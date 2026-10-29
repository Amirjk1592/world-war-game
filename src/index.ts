import config from "../config.json";
import { Env } from "./lib/economy";

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);

    if (url.pathname === "/api/health") {
      const row = await env.DB.prepare("SELECT value FROM game_state WHERE key = 'day'").first<{ value: string }>();
      return json({ ok: true, day: row?.value ?? null });
    }

    // لیست کشورها و طبقه‌ها برای فرانت‌اند
    if (url.pathname === "/api/config/countries") {
      return json({ tiers: config.tiers, countries: config.countries });
    }

    // TODO گام ۳: /api/register, /api/login (JWT), /api/country/pick, /api/dashboard

    return json({ error: "not_found" }, 404);
  },

  // کرون روزانه ۰۰:۰۰ UTC: فقط کارهای سبک (CPU رایگان = ۱۰ میلی‌ثانیه!)
  async scheduled(_event: ScheduledController, env: Env): Promise<void> {
    await env.DB.prepare("UPDATE game_state SET value = CAST(value AS INTEGER) + 1 WHERE key = 'day'").run();
    // TODO: نوسان قیمت بازار، رویداد روزانه، پایان ساخت‌ها
  },
};
