# Camera ao vivo Bem Barato

Arquivos para publicar a pagina em `https://bembarato.shop/cam`.

## O que fica no GitHub

- `index.html`
- `assets/styles.css`
- `assets/app.js`
- `config.js`

A pagina esta pronta para usar o stream publico:

```text
https://bembarato.shop/cam-live/stream.html?src=camera_xmeye_h264
```

## O que precisa rodar no computador da camera

O GitHub Pages entrega apenas arquivos estaticos. Para a camera aparecer fora da rede local, publique o `go2rtc` em um endpoint HTTPS e aponte o caminho publico `/cam-live` para:

```text
http://127.0.0.1:1984
```

O script local esta em:

```powershell
.\scripts\start-camera-public.ps1
```

Ele usa `scripts\camera.local.ps1`, que fica fora do Git por seguranca.

## URLs locais

Painel local:

```text
http://127.0.0.1:1984/
```

Stream local:

```text
http://127.0.0.1:1984/stream.html?src=camera_xmeye_h264
```

Snapshot local:

```text
http://127.0.0.1:1984/api/frame.jpeg?src=camera_xmeye_h264
```
