(() => {
  const button = document.querySelector('.copy-command');
  const command = document.querySelector('#brew-command');
  const status = document.querySelector('.copy-status');
  if (!button || !command || !status) return;
  let resetTimer;
  button.hidden = false;
  button.addEventListener('click', async () => {
    clearTimeout(resetTimer);
    try {
      await navigator.clipboard.writeText(command.textContent.trim());
      button.textContent = 'Copied';
      status.textContent = 'Command copied.';
      resetTimer = setTimeout(() => {
        button.textContent = 'Copy';
        status.textContent = '';
      }, 2500);
    } catch {
      const selection = window.getSelection();
      const range = document.createRange();
      range.selectNodeContents(command);
      selection?.removeAllRanges();
      selection?.addRange(range);
      button.textContent = 'Copy';
      status.textContent = 'Copy unavailable. Select the command and copy it manually.';
    }
  });
})();
