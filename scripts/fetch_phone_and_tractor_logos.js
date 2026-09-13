const fs = require('fs');
const path = require('path');
const https = require('https');

const items = [
  // Telefoni
  { id: 'apple', folder: 'phone_brands', title: 'File:Apple_logo_black.svg', wiki: 'commons' },
  { id: 'samsung', folder: 'phone_brands', title: 'File:Samsung_logo.svg', wiki: 'commons' },
  { id: 'xiaomi', folder: 'phone_brands', title: 'File:Xiaomi_logo_(2021-).svg', wiki: 'commons' },
  { id: 'redmi', folder: 'phone_brands', title: 'File:Redmi_Logo.svg', wiki: 'commons' },
  { id: 'poco', folder: 'phone_brands', title: 'File:Poco Logo Transparent.png', wiki: 'commons' },
  { id: 'honor', folder: 'phone_brands', title: 'File:Honor Logo (2020).svg', wiki: 'commons' },
  { id: 'motorola', folder: 'phone_brands', title: 'File:Motorola_logo.svg', wiki: 'commons' },
  { id: 'realme', folder: 'phone_brands', title: 'File:Realme_logo.svg', wiki: 'commons' },
  { id: 'vivo', folder: 'phone_brands', title: 'File:Vivo_logo_2019.svg', wiki: 'commons' },
  { id: 'google', folder: 'phone_brands', title: 'File:Google 2015 logo.svg', wiki: 'commons' },
  { id: 'huawei', folder: 'phone_brands', title: 'File:Huawei_Standard_logo.svg', wiki: 'en.wikipedia' },
  { id: 'sony', folder: 'phone_brands', title: 'File:Sony_logo.svg', wiki: 'commons' },
  { id: 'nothing', folder: 'phone_brands', title: 'File:Nothing_logo.svg', wiki: 'commons' },
  { id: 'asus', folder: 'phone_brands', title: 'File:ASUS_Logo.svg', wiki: 'commons' },
  { id: 'zte', folder: 'phone_brands', title: 'File:ZTE logo new.png', wiki: 'commons' },
  { id: 'nokia_hmd', folder: 'phone_brands', title: 'File:Nokia_wordmark.svg', wiki: 'commons' },
  { id: 'cat', folder: 'phone_brands', title: 'File:Caterpillar_logo.svg', wiki: 'commons' },

  // Traktori
  { id: 'traktori_zetor_ursus', folder: 'tractor_brands', title: 'File:Zetor Logo.svg', wiki: 'commons' },
  { id: 'traktori_zapadni', folder: 'tractor_brands', title: 'File:John Deere text only.png', wiki: 'commons' },
];

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'User-Agent': 'MlekoApp/1.0 (bgzoners@gmail.com)' } }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

function downloadFile(url, dest) {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(dest);
    https.get(url, { headers: { 'User-Agent': 'MlekoApp/1.0 (bgzoners@gmail.com)' } }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return downloadFile(res.headers.location, dest).then(resolve).catch(reject);
      }
      if (res.statusCode !== 200) {
        return reject(new Error(`Failed with status ${res.statusCode} for ${url}`));
      }
      res.pipe(file);
      file.on('finish', () => {
        file.close(resolve);
      });
    }).on('error', (err) => {
      fs.unlink(dest, () => {});
      reject(err);
    });
  });
}

async function main() {
  for (const item of items) {
    const dest = path.join(__dirname, '..', 'assets', 'images', item.folder, `${item.id}.png`);
    try {
      const baseDomain = item.wiki === 'en.wikipedia' ? 'en.wikipedia.org' : 'commons.wikimedia.org';
      const apiUrl = `https://${baseDomain}/w/api.php?action=query&titles=${encodeURIComponent(item.title)}&prop=imageinfo&iiprop=url&iiurlwidth=320&format=json`;
      const data = await fetchJson(apiUrl);
      const pages = data?.query?.pages;
      if (!pages) throw new Error('No pages returned');
      const page = Object.values(pages)[0];
      const imgUrl = page?.imageinfo?.[0]?.thumburl || page?.imageinfo?.[0]?.url;
      if (!imgUrl) {
        console.warn(`[NOT FOUND] ${item.id} (${item.title})`);
        continue;
      }
      await downloadFile(imgUrl, dest);
      const size = fs.statSync(dest).size;
      console.log(`[OK] ${item.id}.png (${size} bytes) -> ${item.folder}`);
    } catch (e) {
      console.error(`[ERROR] ${item.id}:`, e.message);
    }
  }
}

main().catch(console.error);
