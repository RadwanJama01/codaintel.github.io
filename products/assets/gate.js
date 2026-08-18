/*
 * Client-side password gate. This is a soft friction layer for a static
 * site with no backend, not real access control: the hash below and the
 * protected DOM content are both delivered to the browser regardless of
 * whether the check passes, so anyone reading source/devtools/network can
 * see everything. Do not put content here that needs to actually stay
 * confidential.
 */
(function () {
  var CRED_HASH = 'fbe5241e21fd7053b3577c647d386d8ae1b2177e9162d805eafe5e5f7018b91a';
  var STORAGE_KEY = 'prg-gate-ok';

  async function sha256(text) {
    var enc = new TextEncoder().encode(text);
    var buf = await crypto.subtle.digest('SHA-256', enc);
    return Array.from(new Uint8Array(buf)).map(function (b) {
      return b.toString(16).padStart(2, '0');
    }).join('');
  }

  function reveal() {
    var gate = document.getElementById('gate');
    var content = document.getElementById('protected');
    if (gate) gate.style.display = 'none';
    if (content) content.style.display = 'block';
  }

  if (sessionStorage.getItem(STORAGE_KEY) === '1') {
    reveal();
    return;
  }

  document.addEventListener('DOMContentLoaded', function () {
    var form = document.getElementById('gate-form');
    var error = document.getElementById('gate-error');
    if (!form) return;

    form.addEventListener('submit', async function (e) {
      e.preventDefault();
      var user = document.getElementById('gate-user').value.trim();
      var pass = document.getElementById('gate-pass').value;
      var hash = await sha256(user + ':' + pass);

      if (hash === CRED_HASH) {
        sessionStorage.setItem(STORAGE_KEY, '1');
        reveal();
      } else {
        error.style.display = 'block';
      }
    });
  });
})();
