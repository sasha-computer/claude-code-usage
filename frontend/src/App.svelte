<script>
  import { Copy, Check, Gauge, Clock, Eye, Shield } from 'lucide-svelte'

  let copied = $state(false)
  const installCmd = 'curl -sL https://raw.githubusercontent.com/sasha-computer/claude-code-usage/main/install.sh | bash'

  function copyInstall() {
    navigator.clipboard.writeText(installCmd)
    copied = true
    setTimeout(() => copied = false, 2000)
  }
</script>

<main>
  <!-- Hero -->
  <section class="hero">
    <img src="/hero.png" alt="" class="blob" />
    <h1>Claude Code Usage</h1>
    <p class="tagline">See your Claude Code rate limits in the macOS menu bar. Always.</p>
  </section>

  <!-- Install -->
  <section class="install">
    <div class="install-block">
      <code>{installCmd}</code>
      <button class="copy-btn" onclick={copyInstall} aria-label="Copy to clipboard">
        {#if copied}
          <Check size={16} strokeWidth={1.5} />
        {:else}
          <Copy size={16} strokeWidth={1.5} />
        {/if}
      </button>
    </div>
  </section>

  <!-- Features -->
  <section class="features">
    <div class="feature">
      <div class="feature-icon"><Gauge size={24} strokeWidth={1.5} /></div>
      <h3>Live usage percentages</h3>
      <p>5-hour and weekly limits shown right in the menu bar. Color-coded: green, orange at 70%, red at 90%.</p>
    </div>
    <div class="feature">
      <div class="feature-icon"><Clock size={24} strokeWidth={1.5} /></div>
      <h3>Reset countdowns</h3>
      <p>Click the menu bar item for exact reset times. Know when your limits roll over without guessing.</p>
    </div>
    <div class="feature">
      <div class="feature-icon"><Eye size={24} strokeWidth={1.5} /></div>
      <h3>Zero config</h3>
      <p>Reads your Claude Code credentials from the macOS Keychain. If you're logged in, it just works.</p>
    </div>
    <div class="feature">
      <div class="feature-icon"><Shield size={24} strokeWidth={1.5} /></div>
      <h3>Private</h3>
      <p>Calls the Anthropic API directly. No middleman server, no telemetry, no data sent anywhere else.</p>
    </div>
  </section>

  <!-- Menu bar preview -->
  <section class="preview">
    <div class="menubar-mock">
      <span class="menubar-text"><span class="green">5h 12%</span>&nbsp;&nbsp;<span class="orange">7d 68%</span></span>
    </div>
    <p class="preview-caption">What it looks like in your menu bar</p>
  </section>

  <!-- Footer -->
  <footer>
    <a href="https://github.com/sasha-computer/claude-code-usage" class="github-link">GitHub</a>
  </footer>
</main>

<style>
  main {
    max-width: var(--content-width);
    margin: 0 auto;
    padding: 0 24px;
  }

  /* Hero */
  .hero {
    text-align: center;
    padding-top: 80px;
  }

  .blob {
    width: 180px;
    height: 180px;
    animation: fadeIn 0.8s ease;
  }

  h1 {
    font-family: var(--mono);
    font-size: 2.8rem;
    font-weight: 400;
    letter-spacing: -0.02em;
    animation: fadeIn 0.8s ease 0.1s both;
  }

  .tagline {
    color: var(--muted);
    font-size: 1.2rem;
    margin-bottom: 32px;
    animation: fadeIn 0.8s ease 0.2s both;
  }

  /* Install */
  .install {
    animation: fadeIn 0.8s ease 0.3s both;
  }

  .install-block {
    display: flex;
    align-items: center;
    gap: 16px;
    width: 100%;
    background: var(--code-bg);
    border: 1px solid rgba(255, 255, 255, 0.06);
    border-radius: 12px;
    padding: 18px 20px;
    transition: box-shadow 0.3s ease, border-color 0.3s ease;
  }

  .install-block:hover {
    border-color: rgba(155, 125, 219, 0.3);
    box-shadow: 0 0 40px var(--accent-glow);
  }

  .install-block code {
    font-family: var(--mono);
    font-size: 0.65rem;
    color: var(--fg);
    flex: 1;
    word-break: break-all;
    line-height: 1.5;
  }

  .copy-btn {
    background: none;
    border: none;
    color: var(--muted);
    cursor: pointer;
    padding: 6px;
    border-radius: 6px;
    transition: color 0.2s, background 0.2s;
    flex-shrink: 0;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .copy-btn:hover {
    color: var(--accent);
    background: rgba(155, 125, 219, 0.1);
  }

  /* Features */
  .features {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
    margin-top: 48px;
    animation: fadeIn 0.8s ease 0.4s both;
  }

  .feature {
    background: var(--code-bg);
    border: 1px solid rgba(255, 255, 255, 0.06);
    border-radius: 12px;
    padding: 24px;
    transition: border-color 0.3s ease, box-shadow 0.3s ease;
  }

  .feature:hover {
    border-color: rgba(155, 125, 219, 0.2);
    box-shadow: 0 0 30px var(--accent-glow);
  }

  .feature-icon {
    color: var(--accent);
    margin-bottom: 12px;
  }

  .feature h3 {
    font-family: var(--mono);
    font-size: 0.95rem;
    font-weight: 400;
    margin-bottom: 8px;
  }

  .feature p {
    color: var(--muted);
    font-size: 0.85rem;
    line-height: 1.6;
  }

  /* Menu bar preview */
  .preview {
    margin-top: 48px;
    text-align: center;
    animation: fadeIn 0.8s ease 0.5s both;
  }

  .menubar-mock {
    display: inline-block;
    background: #2a2a30;
    border-radius: 8px;
    padding: 10px 24px;
    font-family: var(--mono);
    font-size: 0.85rem;
    letter-spacing: 0.02em;
  }

  .menubar-text .green {
    color: #4ade80;
  }

  .menubar-text .orange {
    color: #fb923c;
  }

  .preview-caption {
    color: var(--muted);
    font-size: 0.8rem;
    margin-top: 12px;
  }

  /* Footer */
  footer {
    text-align: center;
    border-top: 1px solid rgba(255, 255, 255, 0.06);
    color: var(--muted);
    font-size: 0.85rem;
    display: flex;
    flex-direction: column;
    gap: 8px;
    margin-top: 48px;
    padding-top: 24px;
    padding-bottom: 40px;
  }

  footer a {
    color: var(--accent);
    text-decoration: none;
  }

  footer a:hover {
    text-decoration: underline;
  }

  .github-link {
    font-family: var(--mono);
    font-size: 0.8rem;
  }

  /* Animation */
  @keyframes fadeIn {
    from { opacity: 0; transform: translateY(12px); }
    to { opacity: 1; transform: translateY(0); }
  }

  /* Mobile */
  @media (max-width: 500px) {
    h1 {
      font-size: 2rem;
    }

    .features {
      grid-template-columns: 1fr;
    }
  }
</style>
