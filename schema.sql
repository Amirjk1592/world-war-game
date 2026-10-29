-- BLACK WAR : D1 (SQLite) schema. پول به‌صورت عدد صحیح (دلار) ذخیره می‌شود.
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  username      TEXT NOT NULL UNIQUE,
  pass_hash     TEXT NOT NULL,
  is_admin      INTEGER NOT NULL DEFAULT 0,
  banned        INTEGER NOT NULL DEFAULT 0,
  signup_ip     TEXT,
  created_at    INTEGER NOT NULL
);

-- وضعیت زنده‌ی هر کشور. id همان id داخل config.json است. owner_id خالی = NPC
CREATE TABLE IF NOT EXISTS countries (
  id              INTEGER PRIMARY KEY,
  code            TEXT NOT NULL UNIQUE,
  owner_id        INTEGER REFERENCES users(id),
  treasury        INTEGER NOT NULL,
  population      INTEGER NOT NULL,
  satisfaction    REAL NOT NULL DEFAULT 70,
  legitimacy      REAL NOT NULL DEFAULT 100,
  gov_type        TEXT NOT NULL DEFAULT 'democracy',
  last_accrual    INTEGER NOT NULL,       -- آخرین زمان محاسبه درآمد (کسلانه)
  shield_until    INTEGER NOT NULL DEFAULT 0,
  newbie_until    INTEGER NOT NULL DEFAULT 0,
  joined_at       INTEGER
);
CREATE INDEX IF NOT EXISTS idx_countries_owner ON countries(owner_id);

CREATE TABLE IF NOT EXISTS stocks (
  country_id INTEGER NOT NULL REFERENCES countries(id),
  resource   TEXT NOT NULL,
  amount     REAL NOT NULL DEFAULT 0,
  PRIMARY KEY (country_id, resource)
);

-- ساختمان‌ها: معدن‌ها، کارخانه‌ها، نیروگاه، مسکن، ...
CREATE TABLE IF NOT EXISTS buildings (
  country_id INTEGER NOT NULL REFERENCES countries(id),
  type       TEXT NOT NULL,
  count      INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (country_id, type)
);

-- صف ساخت (زمان‌دار)
CREATE TABLE IF NOT EXISTS build_queue (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  country_id INTEGER NOT NULL REFERENCES countries(id),
  type       TEXT NOT NULL,
  qty        INTEGER NOT NULL,
  done_at    INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS units (
  country_id INTEGER NOT NULL REFERENCES countries(id),
  unit       TEXT NOT NULL,
  count      INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (country_id, unit)
);

CREATE TABLE IF NOT EXISTS market_prices (
  resource   TEXT PRIMARY KEY,
  price      REAL NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS fronts (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  attacker_id     INTEGER NOT NULL REFERENCES countries(id),
  defender_id     INTEGER NOT NULL REFERENCES countries(id),
  status          TEXT NOT NULL DEFAULT 'active',   -- active | frozen | closed
  attacker_power  REAL NOT NULL DEFAULT 0,
  defender_power  REAL NOT NULL DEFAULT 0,
  started_at      INTEGER NOT NULL,
  closed_at       INTEGER
);

-- موضع کشورها در یک جبهه: attacker_ally | defender_ally | neutral
CREATE TABLE IF NOT EXISTS front_members (
  front_id   INTEGER NOT NULL REFERENCES fronts(id),
  country_id INTEGER NOT NULL REFERENCES countries(id),
  side       TEXT NOT NULL,
  PRIMARY KEY (front_id, country_id)
);

CREATE TABLE IF NOT EXISTS treaties (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  type       TEXT NOT NULL,                 -- nap | alliance
  a_id       INTEGER NOT NULL REFERENCES countries(id),
  b_id       INTEGER NOT NULL REFERENCES countries(id),
  status     TEXT NOT NULL DEFAULT 'active',
  created_at INTEGER NOT NULL
);

-- لاگ همه‌ی تغییرات مالی و منابع (ضدتقلب / Audit)
CREATE TABLE IF NOT EXISTS audit_log (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  ts         INTEGER NOT NULL,
  user_id    INTEGER,
  country_id INTEGER,
  action     TEXT NOT NULL,
  delta      TEXT,                          -- JSON
  ip         TEXT
);
CREATE INDEX IF NOT EXISTS idx_audit_country ON audit_log(country_id, ts);

-- کلید-مقدار: فازها (war_enabled, trade_enabled, ...)، شماره روز، رویداد فعال
CREATE TABLE IF NOT EXISTS game_state (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

-- تغییر بالانس به‌صورت زنده بدون deploy: مقدار اینجا بر config.json غلبه می‌کند
CREATE TABLE IF NOT EXISTS config_override (
  path  TEXT PRIMARY KEY,                   -- مثلا economy.resources.oil.base_price
  value TEXT NOT NULL
);

INSERT OR IGNORE INTO game_state(key,value) VALUES
  ('day','0'),
  ('season_start','0'),
  ('phase_war','0'),
  ('phase_trade','1'),
  ('phase_build','1'),
  ('phase_buy_units','1');
