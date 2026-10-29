import config from "../../config.json";

export interface Env {
  DB: D1Database;
}

const DAY_MS = 86_400_000;

/**
 * درآمد کسلانه: به جای نوشتن در هر تیک، فقط وقتی کشور خوانده می‌شود
 * (یا اکشنی انجام می‌دهد) تولید از last_accrual تا الان محاسبه و یک‌بار ذخیره می‌شود.
 * این کار نوشتن‌های روزانه‌ی D1 را بسیار کم نگه می‌دارد (سقف رایگان: ۱۰۰ هزار در روز).
 *
 * فعلا: فقط تولید معدن‌ها به انبار. بعدا: کارگر، برق، مصرف غذا، نگهداری ارتش.
 */
export async function accrue(env: Env, countryId: number, now = Date.now()): Promise<void> {
  const row = await env.DB.prepare("SELECT last_accrual FROM countries WHERE id = ?")
    .bind(countryId).first<{ last_accrual: number }>();
  if (!row) return;

  const days = (now - row.last_accrual) / DAY_MS;
  if (days <= 0) return;

  const mines = await env.DB.prepare(
    "SELECT type, count FROM buildings WHERE country_id = ? AND type LIKE 'mine_%'"
  ).bind(countryId).all<{ type: string; count: number }>();

  const stmts: D1PreparedStatement[] = [];
  const resCfg = config.economy.resources as Record<string, { per_mine_day: number }>;

  for (const m of mines.results ?? []) {
    const resource = m.type.replace("mine_", "");
    const rc = resCfg[resource];
    if (!rc) continue;
    const produced = m.count * rc.per_mine_day * days;
    stmts.push(
      env.DB.prepare(
        `INSERT INTO stocks(country_id, resource, amount) VALUES (?, ?, ?)
         ON CONFLICT(country_id, resource) DO UPDATE SET amount = amount + excluded.amount`
      ).bind(countryId, resource, produced)
    );
  }

  stmts.push(env.DB.prepare("UPDATE countries SET last_accrual = ? WHERE id = ?").bind(now, countryId));
  await env.DB.batch(stmts);
}
