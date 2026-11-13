import { assertEquals, assert } from "jsr:@std/assert";
import {
  handleUploadRequest,
  MAX_UPLOAD_BYTES,
  type MediaBucket,
  type UploadEnv,
} from "../functions/api/upload.ts";

const USER_ID = "11111111-1111-4111-8111-111111111111";
const OTHER_USER_ID = "22222222-2222-4222-8222-222222222222";
const VALID_JPEG = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]);
const VALID_PNG = new Uint8Array([
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
]);
const VALID_WEBP = new Uint8Array([
  0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50,
]);

class MockBucket implements MediaBucket {
  putCalls: Array<{ key: string; byteLength: number; contentType?: string }> = [];
  deleteCalls: Array<string | string[]> = [];

  async put(
    key: string,
    value: ReadableStream<Uint8Array> | ArrayBuffer | ArrayBufferView | string | Blob | null,
    options?: { httpMetadata?: { contentType?: string } },
  ): Promise<void> {
    let byteLength = 0;
    if (value instanceof ArrayBuffer) {
      byteLength = value.byteLength;
    } else if (ArrayBuffer.isView(value)) {
      byteLength = value.byteLength;
    }
    this.putCalls.push({
      key,
      byteLength,
      contentType: options?.httpMetadata?.contentType,
    });
  }

  async delete(keys: string | string[]): Promise<void> {
    this.deleteCalls.push(keys);
  }
}

function makeAuthFetcher(
  mode: "valid" | "anonymous" | "invalid",
): typeof fetch {
  return async (input, init) => {
    const url = typeof input === "string" ? input : input.toString();
    assert(url.endsWith("/auth/v1/user"), `Unexpected auth URL: ${url}`);
    assertEquals(
      (init?.headers as Record<string, string>)?.apikey,
      "anon-test-key",
    );

    if (mode === "invalid") {
      return new Response(JSON.stringify({ message: "Invalid JWT" }), {
        status: 401,
      });
    }
    if (mode === "anonymous") {
      return new Response(
        JSON.stringify({
          id: USER_ID,
          is_anonymous: true,
          app_metadata: { provider: "anonymous" },
        }),
        { status: 200 },
      );
    }
    return new Response(
      JSON.stringify({
        id: USER_ID,
        is_anonymous: false,
        app_metadata: { provider: "email" },
      }),
      { status: 200 },
    );
  };
}

function makeEnv(bucket: MediaBucket): UploadEnv {
  return {
    MEDIA_BUCKET: bucket,
    SUPABASE_URL: "https://example.supabase.co",
    SUPABASE_ANON_KEY: "anon-test-key",
  };
}

Deno.test("upload rejects unauthenticated, invalid JWT, and anonymous users", async () => {
  const bucket = new MockBucket();
  const env = makeEnv(bucket);

  const noAuthReq = new Request(
    `https://www.domacimarket.rs/api/upload?path=profiles/${USER_ID}.jpg`,
    {
      method: "POST",
      headers: { "Content-Type": "image/jpeg" },
      body: VALID_JPEG,
    },
  );
  const noAuthRes = await handleUploadRequest(noAuthReq, env, {
    fetchImpl: makeAuthFetcher("valid"),
  });
  assertEquals(noAuthRes.status, 401);

  const invalidJwtReq = new Request(
    `https://www.domacimarket.rs/api/upload?path=profiles/${USER_ID}.jpg`,
    {
      method: "POST",
      headers: {
        Authorization: "Bearer bad-token",
        "Content-Type": "image/jpeg",
      },
      body: VALID_JPEG,
    },
  );
  const invalidJwtRes = await handleUploadRequest(invalidJwtReq, env, {
    fetchImpl: makeAuthFetcher("invalid"),
  });
  assertEquals(invalidJwtRes.status, 401);

  const anonReq = new Request(
    `https://www.domacimarket.rs/api/upload?path=profiles/${USER_ID}.jpg`,
    {
      method: "POST",
      headers: {
        Authorization: "Bearer anon-jwt",
        "Content-Type": "image/jpeg",
      },
      body: VALID_JPEG,
    },
  );
  const anonRes = await handleUploadRequest(anonReq, env, {
    fetchImpl: makeAuthFetcher("anonymous"),
  });
  assertEquals(anonRes.status, 403);
  assertEquals(bucket.putCalls.length, 0);
});

Deno.test("upload restricts CORS to allowlisted origins and permits headerless mobile requests", async () => {
  const bucket = new MockBucket();
  const env = makeEnv(bucket);

  const evilPreflight = new Request("https://www.domacimarket.rs/api/upload", {
    method: "OPTIONS",
    headers: { Origin: "https://evil.example" },
  });
  const evilRes = await handleUploadRequest(evilPreflight, env);
  assertEquals(evilRes.status, 403);
  assertEquals(evilRes.headers.get("Access-Control-Allow-Origin"), null);

  const okPreflight = new Request("https://www.domacimarket.rs/api/upload", {
    method: "OPTIONS",
    headers: { Origin: "https://www.domacimarket.rs" },
  });
  const okPreflightRes = await handleUploadRequest(okPreflight, env);
  assertEquals(okPreflightRes.status, 204);
  assertEquals(
    okPreflightRes.headers.get("Access-Control-Allow-Origin"),
    "https://www.domacimarket.rs",
  );
  assertEquals(okPreflightRes.headers.get("Vary"), "Origin");

  // Headerless native app request succeeds without wildcard ACAO
  const nativeReq = new Request(
    `https://www.domacimarket.rs/api/upload?path=profiles/${USER_ID}.jpg`,
    {
      method: "POST",
      headers: {
        Authorization: "Bearer valid-jwt",
        "Content-Type": "image/jpeg",
      },
      body: VALID_JPEG,
    },
  );
  const nativeRes = await handleUploadRequest(nativeReq, env, {
    fetchImpl: makeAuthFetcher("valid"),
  });
  assertEquals(nativeRes.status, 200);
  assertEquals(nativeRes.headers.get("Access-Control-Allow-Origin"), null);
});

Deno.test("upload and delete enforce path traversal, bucket allowlist, and ownership", async () => {
  const bucket = new MockBucket();
  const env = makeEnv(bucket);

  const badPaths = [
    `product-images/${USER_ID}/../../secret.jpg`,
    `product-images/${USER_ID}/..\\secret.jpg`,
    `unknown-bucket/${USER_ID}/pic.jpg`,
    `product-images/${USER_ID}`,
    `product-images/${USER_ID}//pic.jpg`,
  ];

  for (const path of badPaths) {
    const req = new Request(
      `https://www.domacimarket.rs/api/upload?path=${encodeURIComponent(path)}`,
      {
        method: "POST",
        headers: {
          Authorization: "Bearer valid-jwt",
          "Content-Type": "image/jpeg",
        },
        body: VALID_JPEG,
      },
    );
    const res = await handleUploadRequest(req, env, {
      fetchImpl: makeAuthFetcher("valid"),
    });
    assertEquals(res.status, 400, `Path ${path} should return 400`);
  }

  const foreignTargets = [
    `profiles/${OTHER_USER_ID}.jpg`,
    `product-images/${OTHER_USER_ID}/item.jpg`,
    `farm-gallery/${OTHER_USER_ID}/gal.png`,
  ];

  for (const path of foreignTargets) {
    const postRes = await handleUploadRequest(
      new Request(
        `https://www.domacimarket.rs/api/upload?path=${encodeURIComponent(path)}`,
        {
          method: "POST",
          headers: {
            Authorization: "Bearer valid-jwt",
            "Content-Type": "image/jpeg",
          },
          body: VALID_JPEG,
        },
      ),
      env,
      { fetchImpl: makeAuthFetcher("valid") },
    );
    assertEquals(postRes.status, 403, `POST to ${path} must return 403`);

    const delRes = await handleUploadRequest(
      new Request(
        `https://www.domacimarket.rs/api/upload?path=${encodeURIComponent(path)}`,
        {
          method: "DELETE",
          headers: { Authorization: "Bearer valid-jwt" },
        },
      ),
      env,
      { fetchImpl: makeAuthFetcher("valid") },
    );
    assertEquals(delRes.status, 403, `DELETE of ${path} must return 403`);
  }

  assertEquals(bucket.putCalls.length, 0);
  assertEquals(bucket.deleteCalls.length, 0);
});

Deno.test("upload rejects disallowed MIME, spoofed content, and oversized payloads", async () => {
  const bucket = new MockBucket();
  const env = makeEnv(bucket);

  const svgReq = new Request(
    `https://www.domacimarket.rs/api/upload?path=product-images/${USER_ID}/a.png`,
    {
      method: "POST",
      headers: {
        Authorization: "Bearer valid-jwt",
        "Content-Type": "image/svg+xml",
      },
      body: "<svg></svg>",
    },
  );
  const svgRes = await handleUploadRequest(svgReq, env, {
    fetchImpl: makeAuthFetcher("valid"),
  });
  assertEquals(svgRes.status, 415);

  const spoofedReq = new Request(
    `https://www.domacimarket.rs/api/upload?path=product-images/${USER_ID}/a.jpg`,
    {
      method: "POST",
      headers: {
        Authorization: "Bearer valid-jwt",
        "Content-Type": "image/jpeg",
      },
      body: new TextEncoder().encode("<html><script>alert(1)</script></html>"),
    },
  );
  const spoofedRes = await handleUploadRequest(spoofedReq, env, {
    fetchImpl: makeAuthFetcher("valid"),
  });
  assertEquals(spoofedRes.status, 415);

  const largeHeaderReq = new Request(
    `https://www.domacimarket.rs/api/upload?path=product-images/${USER_ID}/big.jpg`,
    {
      method: "POST",
      headers: {
        Authorization: "Bearer valid-jwt",
        "Content-Type": "image/jpeg",
        "Content-Length": String(MAX_UPLOAD_BYTES + 1),
      },
      body: VALID_JPEG,
    },
  );
  const largeHeaderRes = await handleUploadRequest(largeHeaderReq, env, {
    fetchImpl: makeAuthFetcher("valid"),
  });
  assertEquals(largeHeaderRes.status, 413);

  const oversizedStream = new ReadableStream<Uint8Array>({
    start(controller) {
      const half = Math.ceil((MAX_UPLOAD_BYTES + 1024) / 2);
      controller.enqueue(new Uint8Array(half).fill(0xff));
      controller.enqueue(new Uint8Array(half).fill(0xd8));
      controller.close();
    },
  });
  const streamTooLargeReq = new Request(
    `https://www.domacimarket.rs/api/upload?path=product-images/${USER_ID}/stream.jpg`,
    {
      method: "POST",
      headers: {
        Authorization: "Bearer valid-jwt",
        "Content-Type": "image/jpeg",
      },
      body: oversizedStream,
    },
  );
  const streamTooLargeRes = await handleUploadRequest(streamTooLargeReq, env, {
    fetchImpl: makeAuthFetcher("valid"),
  });
  assertEquals(streamTooLargeRes.status, 413);
  assertEquals(bucket.putCalls.length, 0);
});

Deno.test("upload and delete succeed for owner with valid PNG/WebP/JPEG images", async () => {
  const bucket = new MockBucket();
  const env = makeEnv(bucket);

  const pngRes = await handleUploadRequest(
    new Request(
      `https://www.domacimarket.rs/api/upload?path=product-images/${USER_ID}/p1.png`,
      {
        method: "POST",
        headers: {
          Authorization: "Bearer valid-jwt",
          "Content-Type": "image/png",
          Origin: "https://www.domacimarket.rs",
        },
        body: VALID_PNG,
      },
    ),
    env,
    { fetchImpl: makeAuthFetcher("valid") },
  );
  assertEquals(pngRes.status, 200);
  const pngBody = await pngRes.json();
  assertEquals(pngBody.success, true);
  assertEquals(pngBody.path, `product-images/${USER_ID}/p1.png`);

  const webpRes = await handleUploadRequest(
    new Request(
      `https://www.domacimarket.rs/api/upload?path=farm-gallery/${USER_ID}/g1.webp`,
      {
        method: "POST",
        headers: {
          Authorization: "Bearer valid-jwt",
          "Content-Type": "image/webp",
        },
        body: VALID_WEBP,
      },
    ),
    env,
    { fetchImpl: makeAuthFetcher("valid") },
  );
  assertEquals(webpRes.status, 200);

  const delRes = await handleUploadRequest(
    new Request(
      `https://www.domacimarket.rs/api/upload?path=product-images/${USER_ID}/p1.png`,
      {
        method: "DELETE",
        headers: { Authorization: "Bearer valid-jwt" },
      },
    ),
    env,
    { fetchImpl: makeAuthFetcher("valid") },
  );
  assertEquals(delRes.status, 200);
  assertEquals(bucket.putCalls.length, 2);
  assertEquals(bucket.deleteCalls, [`product-images/${USER_ID}/p1.png`]);
});

