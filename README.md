# PrepPilot — Supabase + Vercel deployment

This version uses Supabase Auth + Postgres directly from the browser, and Vercel to host the static frontend. No Express server, Render service, or MongoDB is needed.

## 1. Configure Supabase
1. Open your Supabase project.
2. Go to **SQL Editor → New query**.
3. Paste all contents of `supabase/setup.sql` and click **Run**.
4. Go to **Project Settings → API** (or API Keys) and copy the Project URL and the publishable/anon key. Never use `service_role` or a secret key in frontend code.
5. Open `supabase-config.js` and replace both placeholder values with your URL and publishable/anon key.

## 2. Push the project to GitHub
Upload these files/folders at repository root:
- `index.html`
- `supabase-config.js`
- `supabase/setup.sql`
- `README.md`
- `vercel.json`

Do not upload any private server keys. The Supabase browser publishable/anon key is designed for client use only when Row Level Security is enabled and policies are correctly configured.

## 3. Deploy to Vercel
1. Sign in at https://vercel.com/ using your GitHub account.
2. Click **Add New → Project**, import the repository.
3. Framework Preset: **Other**. Build command: leave blank. Output Directory: `.` (or leave default if Vercel detects static files).
4. Click **Deploy**.
5. Open the generated Vercel URL.

## 4. Configure Supabase Auth URLs
In Supabase Dashboard, open **Authentication → URL Configuration**:
- Set Site URL to your Vercel production URL.
- Add the Vercel URL to Redirect URLs, including preview URLs only if you use them.
- For the easiest demo, disable email confirmation only if you intentionally want instant signup and understand the security tradeoff. Otherwise, keep confirmation enabled and users must verify email.

## 5. Test
- Sign up with a test email/password (use at least 8 characters).
- Confirm email if Supabase requires it, then log in.
- Run a mock test and analyze a resume while signed in.
- Refresh the page. Dashboard results and tasks should remain saved.
- Create a second test account to confirm users cannot see each other's records.

## What is connected
- Supabase Auth registration/login
- RLS-protected per-user profiles, resume score/feedback history, mock scores, and task checklist
- Daily streak updates
- Vercel static hosting

## Limitations
Resume analysis is a transparent rule-based demo score, not an AI/LLM assessment. This implementation stores the score and feedback, not the pasted resume text. Payments, coach booking, real placement verification, and AI API calls are not connected. For an AI model, add a server-side Vercel Function and keep the model API key in Vercel environment variables; never expose secret keys in `index.html` or `supabase-config.js`.
