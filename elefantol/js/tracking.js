document.addEventListener('DOMContentLoaded', function () {
  // Função para gerar UUID
  function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
      const r = (Math.random() * 16) | 0,
        v = c === 'x' ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });
  }

  // Função para obter ou criar um identificador único para o visitante
  function getOrCreateVisitorId() {
    let visitorId = localStorage.getItem('visitorId');
    if (!visitorId) {
      visitorId = generateUUID();
      localStorage.setItem('visitorId', visitorId);
    }
    return visitorId;
  }

  // Verifica disponibilidade de localStorage
  function checkLocalStorage() {
    try {
      localStorage.setItem('test', 'test');
      localStorage.removeItem('test');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Coleta informações do ambiente do cliente
  function getClientInfo() {
    const env = {
      userAgent: navigator.userAgent || 'unknown',
      cookiesEnabled: navigator.cookieEnabled || false,
      doNotTrack: navigator.doNotTrack || '0',
      language: navigator.language || 'unknown',
      platform: navigator.platform || 'unknown',
      vendor: navigator.vendor || 'unknown',
      screenWidth: window.innerWidth || 0,
      screenHeight: window.innerHeight || 0,
      pixelRatio: window.devicePixelRatio || 1,
      localStorage: checkLocalStorage(),
      referrer: document.referrer || 'direct',
      connectionType: 'unknown',
      downlink: null,
      rtt: null,
      privateMode: 'unknown',
    };

    if (navigator.connection) {
      env.connectionType = navigator.connection.effectiveType || 'unknown';
      env.downlink = navigator.connection.downlink || null;
      env.rtt = navigator.connection.rtt || null;
    }

    try {
      const fs = window.RequestFileSystem || window.webkitRequestFileSystem;
      if (fs) {
        env.privateMode = false;
        fs(
          window.TEMPORARY,
          100,
          () => {
            env.privateMode = false;
          },
          () => {
            env.privateMode = true;
          },
        );
      }
    } catch (e) {
      env.privateMode = 'error';
    }

    Object.keys(env).forEach((key) => {
      if (env[key] === undefined) {
        env[key] = null;
      }
    });

    return env;
  }

  const visitorId = getOrCreateVisitorId();
  const clientInfo = getClientInfo();

  // Função para obter o valor do parâmetro 'token' da URL do script
  function getScriptToken() {
    const scripts = document.getElementsByTagName('script');
    for (let script of scripts) {
      if (script.src.includes('tracking.js')) {
        const url = new URL(script.src);
        return url.searchParams.get('token');
      }
    }
    return null;
  }

  function getPlatform() {
    const scripts = document.getElementsByTagName('script');
    for (let script of scripts) {
      if (script.src.includes('tracking.js')) {
        const url = new URL(script.src);
        return url.searchParams.get('platform');
      }
    }
    return null;
  }

  const token = getScriptToken();
  if (!token) {
    console.error('Tracking token is missing.');
    return;
  }

  const platform = getPlatform();
  if (!platform) {
    console.error('Plataform is missing.');
    return;
  }

  // Captura parâmetros de URL e adiciona a todos os links da página
  const params = new URLSearchParams(window.location.search);
  const gclidValue = params.get('gclid'); // Captura o valor de gclid da URL
  params.set('idvi', visitorId); // Adiciona `idvi` com `visitorId` nos parâmetros

  document.querySelectorAll('a').forEach((link) => {
    // Verifica se o link tem um href válido
    if (!link.href || !link.href.trim() || link.href.startsWith('javascript:')) {
      return; // Pula este link e vai para o próximo
    }

    try {
      const url = new URL(link.href);

      if (gclidValue) {
        url.searchParams.set('extclid', gclidValue);
      }

      // Adiciona outros parâmetros da URL ao link
      params.forEach((value, key) => {
        if (
          value &&
          [
            'utm_source',
            'utm_medium',
            'utm_campaign',
            'utm_term',
            'utm_content',
            'src',
            'idvi',
            'gclid',
          ].includes(key)
        ) {
          url.searchParams.set(key, value);
        }
      });
      const platformParams = {
        kiwify: ['src'],
        hotmart: ['src', 'xcod'],
        clickbank: ['extclid'],
        buygoods: ['subid2'],
        digistore: ['cid'],
        adcombo: ['clickid'],
        maxweb: ['subid2'],
        perfectpay: ['track'],
        webvork: ['utm_campaign'],
        smartadv: ['sub3'],
        drcash: ['sub2'],
      };

      if (platformParams[platform]) {
        platformParams[platform].forEach(param => {
          url.searchParams.set(param, visitorId);
        });
      }

      link.href = url.toString();
    } catch (error) {
      console.warn('Link inválido ignorado:', link.href);
    }
  });

  //Caso tenha o parâmetro keywords, será atribuido à varivável keyWords
  let keyWords = '';
  params.get('keyword')
  ? keyWords = params.get('keyword')
  : keyWords = 'none';
  // Função para enviar dados ao servidor
  function sendData(eventType, eventData = {}) {
    const payload = {
      token,
      visitorId, // Inclui o visitorId no payload enviado
      eventType,
      eventData,
      url: window.location.href,
      keyWords,
      timestamp: new Date().toISOString(),
      clientInfo,
    };
    fetch('https://app.superpixelpro.top/api/receive-data', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
      .then((response) =>
        response.ok
          ? console.log('Event tracked successfully')
          : console.error('Failed to track event'),
      )
      .catch((error) => console.error('Tracking error:', error));
  }

  // Envia evento inicial da página carregada
  sendData('page_loaded');

  // Monitora cliques nos links para rastrear interações
  document.addEventListener('click', function (e) {
    if (e.target.tagName === 'A') {
      sendData('link_clicked', { href: e.target.href });
    }
  });

  // Monitora o scroll da página
  let lastScrollTop = 0;
  window.addEventListener('scroll', function () {
    const scrollPercentage = Math.round(
      (window.scrollY / (document.documentElement.scrollHeight - window.innerHeight)) * 100,
    );
    if (Math.abs(scrollPercentage - lastScrollTop) >= 10) {
      sendData('scroll', { percentage: scrollPercentage });
      lastScrollTop = scrollPercentage;
    }
  });

  // Monitora saída da página
  window.addEventListener('beforeunload', () => sendData('page_exit'));
});
