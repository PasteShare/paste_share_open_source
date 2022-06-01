![ScreensShot](./assets/web/favicon.ico)
# PasteShare v1.0.0

A Cross-Platform ( macOS / iOS / Android / Windows / Ubuntu ) clipboard tool on LAN.

## Getting Started

### SSL

1. [how to generate a self signed ssl certificate using openssl](https://stackoverflow.com/questions/10175812/how-to-generate-a-self-signed-ssl-certificate-using-openssl)
2. rename cert to `server_chain.pem` and rename key to `server_key.pem`
3. mv them to `./assets/certificates`.
4. trust your self-signed ssl certificate on `./lib/utils/http.dart` line 12.

### Flutter

For help getting started with Flutter, follow [online documentation](https://flutter.dev/docs)


## Available on Apple App Store and Google Play

[https://pasteshare.app](https://pasteshare.app)

## ScreensShot

![ScreensShot](./assets/web/public-1617844480.8512568.png)
