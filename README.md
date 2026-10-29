# BLACK WAR: گام ۱ (اسکلت پروژه)

## پیش‌نیاز
Node.js نسخه ۲۰ یا بالاتر و یک حساب Cloudflare.

## اجرا
```bash
npm install
npx wrangler login
npx wrangler d1 create blackwar-db      # database_id را در wrangler.jsonc جایگزین کنید
npm run db:init                          # ساخت جدول‌ها روی دیتابیس لوکال
npm run dev                              # http://localhost:8787/api/health
```

## انتشار
```bash
npm run db:init:remote
npm run deploy
```

## ساختار
- `config.json`: همه اعداد بالانس (۴۰ کشور، منابع، ساختمان‌ها، واحدها، قوانین)
- `schema.sql`: جدول‌های D1
- `src/index.ts`: API و کرون روزانه
- `src/lib/economy.ts`: درآمد کسلانه (کم‌نوشتن برای پلن رایگان)
- `web/`: فرانت‌اند (گام بعد)

## نکته
بالانس زنده بدون deploy: مقدار را در جدول `config_override` بنویسید (در گام‌های بعد به کد وصل می‌شود).
