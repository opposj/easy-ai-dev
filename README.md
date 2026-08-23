### Start From Here

- **Build:** `docker build [--build-arg TIER={lite|default|full}] [--build-arg AGENT={from USERAGENT.md}] -t ai-dev[:{lite|default|full}-{from USERAGENT.md}] .`
- **Run:** `docker run -it --rm --privileged ai-dev[:{lite|default|full}-{from USERAGENT.md}]`
- **Note:** 
  1. By default, `full` profile is chosen. `lite` is suitable for headless environments, while `default` and `full` are designed for interactive use. The default agent is `forgecode`, multiple agents are separated by commas
  2. For convenience, `deepseek-v4-flash-vision-exp` is assumed to be used for all agents
