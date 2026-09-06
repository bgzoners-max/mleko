const fs = require('fs');
const path = require('path');
const https = require('https');

const brands = [
  { id: 'auto_volkswagen', slug: 'volkswagen' },
  { id: 'auto_bmw', slug: 'bmw' },
  { id: 'auto_mercedes_benz', slug: 'mercedes-benz' },
  { id: 'auto_audi', slug: 'audi' },
  { id: 'auto_porsche', slug: 'porsche' },
  { id: 'auto_opel', slug: 'opel' },
  { id: 'auto_toyota', slug: 'toyota' },
  { id: 'auto_honda', slug: 'honda' },
  { id: 'auto_nissan', slug: 'nissan' },
  { id: 'auto_mazda', slug: 'mazda' },
  { id: 'auto_subaru', slug: 'subaru' },
  { id: 'auto_suzuki', slug: 'suzuki' },
  { id: 'auto_mitsubishi', slug: 'mitsubishi' },
  { id: 'auto_lexus', slug: 'lexus' },
  { id: 'auto_hyundai', slug: 'hyundai' },
  { id: 'auto_kia', slug: 'kia' },
  { id: 'auto_ford', slug: 'ford' },
  { id: 'auto_chevrolet', slug: 'chevrolet' },
  { id: 'auto_tesla', slug: 'tesla' },
  { id: 'auto_jeep', slug: 'jeep' },
  { id: 'auto_cadillac', slug: 'cadillac' },
  { id: 'auto_rivian', slug: 'rivian' },
  { id: 'auto_fiat', slug: 'fiat' },
  { id: 'auto_alfa_romeo', slug: 'alfa-romeo' },
  { id: 'auto_ferrari', slug: 'ferrari' },
  { id: 'auto_maserati', slug: 'maserati' },
  { id: 'auto_lamborghini', slug: 'lamborghini' },
  { id: 'auto_renault', slug: 'renault' },
  { id: 'auto_peugeot', slug: 'peugeot' },
  { id: 'auto_citroen', slug: 'citroen' },
  { id: 'auto_bugatti', slug: 'bugatti' },
  { id: 'auto_jaguar', slug: 'jaguar' },
  { id: 'auto_land_rover', slug: 'land-rover' },
  { id: 'auto_aston_martin', slug: 'aston-martin' },
  { id: 'auto_bentley', slug: 'bentley' },
  { id: 'auto_rolls_royce', slug: 'rolls-royce' },
  { id: 'auto_byd', slug: 'byd' },
  { id: 'auto_nio', slug: 'nio' },
  { id: 'auto_xpeng', slug: 'xpeng' },
  { id: 'auto_zeekr', slug: 'zeekr' },
  { id: 'auto_mg', slug: 'mg' },
  { id: 'auto_volvo', slug: 'volvo' },
  { id: 'auto_polestar', slug: 'polestar' },
  { id: 'auto_skoda', slug: 'skoda' },
  { id: 'auto_seat', slug: 'seat' },
  { id: 'auto_cupra', slug: 'cupra' },
  { id: 'auto_dacia', slug: 'dacia' },
  { id: 'auto_lada', slug: 'lada' },
];

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
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
    https.get(url, (res) => {
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
  console.log('Fetching dataset metadata...');
  const dataset = await fetchJson('https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/data.json');
  console.log(`Loaded ${dataset.length} logos from dataset.`);

  const outDir = path.join(__dirname, '..', 'assets', 'images', 'car_brands');
  if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir, { recursive: true });
  }

  let successCount = 0;
  for (const b of brands) {
    let item = dataset.find(d => d.slug === b.slug);
    if (!item) {
      item = dataset.find(d => d.slug.includes(b.slug) || d.name.toLowerCase().includes(b.slug));
    }

    if (!item) {
      console.warn(`[MISSING] No match found for ${b.id} (${b.slug})`);
      continue;
    }

    const imgUrl = item.image.optimized || item.image.thumb;
    const dest = path.join(outDir, `${b.id}.png`);
    try {
      await downloadFile(imgUrl, dest);
      const size = fs.statSync(dest).size;
      console.log(`[OK] ${b.id}.png downloaded (${size} bytes) from ${imgUrl}`);
      successCount++;
    } catch (e) {
      console.error(`[ERROR] Failed to download ${b.id} from ${imgUrl}:`, e.message);
    }
  }

  console.log(`\nFinished: ${successCount} / ${brands.length} logos downloaded to ${outDir}`);
}

main().catch(console.error);
