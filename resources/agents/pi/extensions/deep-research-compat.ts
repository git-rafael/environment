import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

interface ExtractResult {
  title: string;
  url: string;
  content: string;
  author?: string;
  publishedDate?: string;
  wordCount: number;
}

async function extractContent(url: string): Promise<ExtractResult> {
  const resp = await fetch(url, {
    headers: {
      "User-Agent": "Mozilla/5.0 (compatible; PiDeepResearchCompat/1.0)",
      Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    },
    redirect: "follow",
    signal: AbortSignal.timeout(15000),
  });

  if (!resp.ok) throw new Error(`Failed to fetch ${url}: ${resp.status}`);

  const html = await resp.text();
  const titleMatch = html.match(/<title[^>]*>(.*?)<\/title>/is);
  const title = titleMatch?.[1]?.replace(/&[^;]+;/g, " ").trim() ?? "";

  let content = html
    .replace(/<script[\s\S]*?<\/script>/gi, "")
    .replace(/<style[\s\S]*?<\/style>/gi, "")
    .replace(/<nav[\s\S]*?<\/nav>/gi, "")
    .replace(/<header[\s\S]*?<\/header>/gi, "")
    .replace(/<footer[\s\S]*?<\/footer>/gi, "")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/&[^;]+;/g, " ")
    .replace(/\s+/g, " ")
    .trim();

  const words = content.split(/\s+/).filter(Boolean);
  const wordCount = words.length;
  if (words.length > 8000) {
    content = `${words.slice(0, 8000).join(" ")}\n\n[... truncated, total ${wordCount} words]`;
  }

  const authorMatch = html.match(/<meta[^>]*name=["']author["'][^>]*content=["']([^"']+)["']/i);
  const author = authorMatch?.[1];

  const dateMatch = html.match(/<meta[^>]*(?:property=["']article:published_time["']|name=["']date["'])[^>]*content=["']([^"']+)["']/i);
  const publishedDate = dateMatch?.[1];

  return { title, url, content, author, publishedDate, wordCount };
}

export default function (pi: ExtensionAPI) {
  // Compatibility layer for pi-deep-research when its upstream extension is disabled.
  // The upstream extension registers a `web_search` tool that conflicts with pi-web-access.
  // Keep pi-web-access as the canonical `web_search`, and provide only the missing tools
  // required by the pi-deep-research skill and /research prompt.
  pi.registerTool({
    name: "web_extract",
    label: "Web Extract",
    description: [
      "Extract the main text content from a web page URL.",
      "Strips HTML, scripts, navigation, and returns clean text.",
      "Use after web_search to read full content of promising results.",
    ].join(" "),
    parameters: Type.Object({
      url: Type.String({ description: "URL of the web page to extract content from" }),
    }),

    async execute(_toolCallId, params) {
      try {
        const result = await extractContent(params.url);
        let text = `# ${result.title}\n\n`;
        text += `**URL:** ${result.url}\n`;
        if (result.author) text += `**Author:** ${result.author}\n`;
        if (result.publishedDate) text += `**Published:** ${result.publishedDate}\n`;
        text += `**Word count:** ${result.wordCount}\n\n---\n\n`;
        text += result.content;
        return { content: [{ type: "text", text }] };
      } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : String(e);
        return {
          content: [{ type: "text", text: `Failed to extract content from ${params.url}: ${msg}` }],
          isError: true,
        };
      }
    },
  });

  const DEPTH_THRESHOLDS: Record<string, {
    minSearchRounds: number;
    maxSearchRounds: number;
    minSources: number;
    confidenceThreshold: number;
    minAnsweredRatio: number;
  }> = {
    quick: { minSearchRounds: 1, maxSearchRounds: 3, minSources: 3, confidenceThreshold: 60, minAnsweredRatio: 0.6 },
    standard: { minSearchRounds: 2, maxSearchRounds: 6, minSources: 5, confidenceThreshold: 75, minAnsweredRatio: 0.7 },
    deep: { minSearchRounds: 3, maxSearchRounds: 10, minSources: 10, confidenceThreshold: 85, minAnsweredRatio: 0.8 },
    exhaustive: { minSearchRounds: 5, maxSearchRounds: 20, minSources: 15, confidenceThreshold: 95, minAnsweredRatio: 0.9 },
  };

  pi.registerTool({
    name: "research_checkpoint",
    label: "Research Checkpoint",
    description: [
      "MANDATORY after each search round during deep research.",
      "Submit current research state for evaluation.",
      "The tool will analyze your progress and return a VERDICT: CONTINUE (must search more) or PROCEED (may synthesize report).",
      "You MUST obey the verdict — if it says CONTINUE, you must do another search round before calling this again.",
      "Do NOT skip this tool or write the report without a PROCEED verdict.",
    ].join(" "),
    parameters: Type.Object({
      depth: Type.String({ description: 'Research depth level: "quick", "standard", "deep", or "exhaustive"' }),
      round: Type.Number({ description: "Current search round number (1-indexed, increment after each search batch)" }),
      sub_questions: Type.Array(
        Type.Object({
          question: Type.String({ description: "The sub-question" }),
          answered: Type.Boolean({ description: "Whether this sub-question has been adequately answered" }),
          confidence: Type.Number({ description: "Confidence score 0-100 for this sub-question" }),
          source_count: Type.Number({ description: "Number of sources found for this sub-question" }),
          best_source_tier: Type.Number({ description: "Best source credibility tier (1=authoritative, 2=reliable, 3=community, 4=unverified)" }),
        }),
        { description: "Status of each sub-question" },
      ),
      total_sources: Type.Number({ description: "Total unique sources collected so far" }),
      contradictions: Type.Optional(Type.Array(Type.String(), { description: "List of contradictions found between sources" })),
      gaps: Type.Optional(Type.Array(Type.String(), { description: "Known information gaps that remain" })),
    }),

    async execute(_toolCallId, params) {
      const thresholds = DEPTH_THRESHOLDS[params.depth] ?? DEPTH_THRESHOLDS.standard;
      const totalQuestions = params.sub_questions.length;
      const answeredCount = params.sub_questions.filter(q => q.answered).length;
      const answeredRatio = totalQuestions > 0 ? answeredCount / totalQuestions : 0;
      const avgConfidence = totalQuestions > 0
        ? params.sub_questions.reduce((sum, q) => sum + q.confidence, 0) / totalQuestions
        : 0;
      const minConfidence = totalQuestions > 0
        ? Math.min(...params.sub_questions.map(q => q.confidence))
        : 0;
      const hasContradictions = (params.contradictions?.length ?? 0) > 0;
      const lowConfidenceQuestions = params.sub_questions.filter(q => q.confidence < 40);
      const medConfidenceQuestions = params.sub_questions.filter(q => q.confidence >= 40 && q.confidence < thresholds.confidenceThreshold);

      const issues: string[] = [];
      let verdict: "CONTINUE" | "PROCEED" = "PROCEED";

      if (params.round < thresholds.minSearchRounds) {
        verdict = "CONTINUE";
        issues.push(`⛔ Min search rounds not met: ${params.round}/${thresholds.minSearchRounds} rounds`);
      }

      if (params.total_sources < thresholds.minSources) {
        verdict = "CONTINUE";
        issues.push(`⛔ Not enough sources: ${params.total_sources}/${thresholds.minSources} sources`);
      }

      if (answeredRatio < thresholds.minAnsweredRatio) {
        verdict = "CONTINUE";
        issues.push(`⛔ Answered ratio too low: ${answeredCount}/${totalQuestions} (${(answeredRatio * 100).toFixed(0)}% < ${(thresholds.minAnsweredRatio * 100).toFixed(0)}%)`);
      }

      if (avgConfidence < thresholds.confidenceThreshold) {
        verdict = "CONTINUE";
        issues.push(`⛔ Average confidence too low: ${avgConfidence.toFixed(0)}% < ${thresholds.confidenceThreshold}%`);
      }

      if (lowConfidenceQuestions.length > 0 && params.round < thresholds.maxSearchRounds) {
        verdict = "CONTINUE";
        const names = lowConfidenceQuestions.map(q => `"${q.question}" (${q.confidence}%)`).join(", ");
        issues.push(`⛔ Low-confidence sub-questions (<40%): ${names}`);
      }

      if (hasContradictions && params.round < thresholds.maxSearchRounds) {
        verdict = "CONTINUE";
        issues.push(`⚠️ Unresolved contradictions (${params.contradictions!.length}) — search for authoritative sources to verify`);
      }

      if (params.round >= thresholds.maxSearchRounds) {
        verdict = "PROCEED";
        if (issues.length > 0) {
          issues.push(`⚠️ Max search rounds reached (${thresholds.maxSearchRounds}). Proceeding to report. Remaining issues will be noted in "Uncertainties & Gaps".`);
        }
      }

      const statusBar = `${"█".repeat(Math.round(avgConfidence / 5))}${"░".repeat(20 - Math.round(avgConfidence / 5))}`;

      let text = `## Research Checkpoint — Round ${params.round}\n\n`;
      text += `**Depth:** ${params.depth} | **Verdict: ${verdict === "CONTINUE" ? "🔴 CONTINUE SEARCHING" : "🟢 PROCEED TO REPORT"}**\n\n`;
      text += "### Progress\n";
      text += `- Search rounds: ${params.round} / ${thresholds.minSearchRounds}-${thresholds.maxSearchRounds}\n`;
      text += `- Sources collected: ${params.total_sources} / ${thresholds.minSources} (minimum)\n`;
      text += `- Sub-questions answered: ${answeredCount}/${totalQuestions} (${(answeredRatio * 100).toFixed(0)}%)\n`;
      text += `- Avg confidence: ${statusBar} ${avgConfidence.toFixed(0)}% (threshold: ${thresholds.confidenceThreshold}%)\n`;
      text += `- Min confidence: ${minConfidence.toFixed(0)}%\n`;

      text += "\n### Sub-question Status\n";
      for (const q of params.sub_questions) {
        const icon = q.confidence >= thresholds.confidenceThreshold ? "✅" : q.confidence >= 40 ? "🟡" : "🔴";
        text += `${icon} [${q.confidence}%] ${q.question} — ${q.source_count} sources (Tier ${q.best_source_tier})\n`;
      }

      if (issues.length > 0) {
        text += "\n### Issues\n";
        for (const issue of issues) text += `${issue}\n`;
      }

      if (params.contradictions && params.contradictions.length > 0) {
        text += "\n### Contradictions\n";
        for (const c of params.contradictions) text += `- ⚡ ${c}\n`;
      }

      if (params.gaps && params.gaps.length > 0) {
        text += "\n### Remaining Gaps\n";
        for (const g of params.gaps) text += `- ❓ ${g}\n`;
      }

      if (verdict === "CONTINUE") {
        text += "\n### 📋 Next Actions Required\n";
        text += "You MUST perform another search round addressing the issues above, then call `research_checkpoint` again.\n";

        if (lowConfidenceQuestions.length > 0) {
          text += "\n**Priority — Low confidence questions to focus on:**\n";
          for (const q of lowConfidenceQuestions) {
            text += `- "${q.question}" — try different search queries, different angles\n`;
          }
        }
        if (medConfidenceQuestions.length > 0) {
          text += "\n**Secondary — Medium confidence questions to strengthen:**\n";
          for (const q of medConfidenceQuestions) {
            text += `- "${q.question}" (${q.confidence}%) — find corroborating sources\n`;
          }
        }
        if (hasContradictions) {
          text += "\n**Resolve contradictions** by searching for authoritative (Tier 1) sources.\n";
        }
      } else {
        text += "\n### ✅ Ready to Synthesize\n";
        text += "All criteria met. Proceed to Phase 4 — write the research report.\n";
        if (params.gaps && params.gaps.length > 0) {
          text += `Include the ${params.gaps.length} remaining gap(s) in the "Uncertainties & Gaps" section of the report.\n`;
        }
        if (hasContradictions) {
          text += `Include the ${params.contradictions!.length} contradiction(s) in the report — present both sides.\n`;
        }
      }

      return { content: [{ type: "text", text }] };
    },
  });
}
