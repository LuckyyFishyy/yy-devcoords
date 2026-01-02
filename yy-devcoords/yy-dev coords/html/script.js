const panel = document.getElementById('dc-panel');
const vec3El = document.getElementById('dc-vec3');
const vec4El = document.getElementById('dc-vec4');
const statusEl = document.getElementById('dc-status');

function postNui(eventName, payload) {
    fetch(`https://${GetParentResourceName()}/${eventName}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(payload || {})
    });
}

function setStatus(text) {
    if (statusEl) statusEl.textContent = text;
}

async function copyText(text) {
    try {
        await navigator.clipboard.writeText(text);
        setStatus('Copied to clipboard.');
    } catch (err) {
        const input = document.createElement('textarea');
        input.value = text;
        document.body.appendChild(input);
        input.select();
        document.execCommand('copy');
        document.body.removeChild(input);
        setStatus('Copied to clipboard.');
    }
}

window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action === 'open') {
        panel.classList.remove('hidden');
        setStatus('Ready');
    } else if (data.action === 'close') {
        panel.classList.add('hidden');
    } else if (data.action === 'update') {
        if (vec3El) vec3El.textContent = data.vec3 || 'vec3(0.00, 0.00, 0.00)';
        if (vec4El) vec4El.textContent = data.vec4 || 'vec4(0.00, 0.00, 0.00, 0.00)';
    } else if (data.action === 'copy' && data.text) {
        copyText(data.text);
    }
});
