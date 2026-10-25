// Minimalne ambient deklaracije tipova za Cloudflare Pages Functions
// (`functions/` direktorijum). Omogućavaju da `npm run type-check`
// (tsc --noEmit) pokriva i Cloudflare Pages verziju, a ne samo Vercel `api/`.
//
// Napomena: kada se pokrene `wrangler types` (generiše pun
// `worker-configuration.d.ts` sa svim Workers Runtime tipovima), ovaj fajl
// treba ukloniti u korist generisanih tipova da ne bi došlo do dupliranja.

declare type R2Bucket = {
  get(key: string): Promise<any>;
  put(
    key: string,
    value: ArrayBuffer | ArrayBufferView | ReadableStream | string,
    options?: any,
  ): Promise<any>;
  head(key: string): Promise<any>;
  delete(key: string): Promise<void>;
  list(options?: any): Promise<any>;
};

declare type PagesFunction<Env = unknown> = (context: {
  request: Request;
  waitUntil(promise: Promise<any>): void;
  next(input?: Request | string, init?: RequestInit): Promise<Response>;
  env: Env;
  params: Record<string, string | string[]>;
  data: Record<string, unknown>;
}) => Promise<Response>;