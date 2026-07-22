(function () {
  const config = window.CAMERA_CONFIG || {};
  const streamName = config.streamName || "camera_xmeye_h264";
  const isLocalHost = ["localhost", "127.0.0.1", ""].includes(window.location.hostname);
  const baseUrl = (isLocalHost ? config.localBaseUrl : config.publicBaseUrl || config.localBaseUrl || "").replace(/\/$/, "");
  const streamUrl = `${baseUrl}/stream.html?src=${encodeURIComponent(streamName)}`;
  const probeUrl = `${baseUrl}/api/streams`;
  const canProbeApi = (() => {
    try {
      return new URL(baseUrl).origin === window.location.origin || isLocalHost;
    } catch (error) {
      return false;
    }
  })();

  const frame = document.getElementById("camera-frame");
  const status = document.getElementById("status");
  const statusText = document.getElementById("status-text");
  const fallback = document.getElementById("fallback");
  const fallbackLink = document.getElementById("fallback-link");
  const reloadButton = document.getElementById("reload-button");
  const cameraLink = document.getElementById("camera-link");

  function setStatus(kind, label) {
    status.classList.remove("is-online", "is-offline");
    if (kind) status.classList.add(kind);
    statusText.textContent = label;
  }

  function loadStream() {
    fallback.hidden = true;
    fallbackLink.href = streamUrl;
    if (cameraLink) {
      cameraLink.href = streamUrl;
    }
    frame.src = `${streamUrl}&t=${Date.now()}`;
    setStatus("", "Conectando");

    window.setTimeout(checkStream, 2500);
  }

  async function checkStream() {
    if (!canProbeApi) {
      setStatus("is-online", "Ao vivo");
      fallback.hidden = true;
      return;
    }

    try {
      const response = await fetch(probeUrl, { cache: "no-store", mode: "cors" });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const streams = await response.json();
      const stream = streams[streamName];

      if (stream && stream.producers && stream.producers.length) {
        setStatus("is-online", "Ao vivo");
        fallback.hidden = true;
        return;
      }

      throw new Error("Stream sem produtor ativo");
    } catch (error) {
      setStatus("is-offline", "Offline");
      fallback.hidden = false;
    }
  }

  reloadButton.addEventListener("click", loadStream);
  frame.addEventListener("load", () => setStatus("is-online", "Ao vivo"));
  loadStream();
  if (canProbeApi) {
    window.setInterval(checkStream, 15000);
  }
})();
