// claude-code asks the model for a status label for every background agent every 30s
// re-sending the agent's context each time with no setting to turn it off
// https://news.ycombinator.com/item?id=50284255
// https://gist.github.com/flamerix-ai/c3905705cc4205e5de3011fa2e74efce
const anchor = "[AgentSummary] Timer fired";
const setTimeout_ = globalThis.setTimeout;
const log = process.env.CC_NO_AGENT_SUMMARY_LOG;

globalThis.setTimeout = function setTimeout(fn, ...rest) {
  if (
    typeof fn === "function" &&
    Function.prototype.toString.call(fn).includes(anchor)
  ) {
    if (log) {
      require("fs").appendFileSync(
        log,
        `${new Date().toISOString()} suppressed agent_summary timer\n`,
      );
    }
    const t = setTimeout_(() => {}, 0);
    clearTimeout(t);
    return t;
  }
  return setTimeout_(fn, ...rest);
};
