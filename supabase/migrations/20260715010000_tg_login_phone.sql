-- Telegram login now PROVES phone ownership: after /start the bot asks the user
-- to share their contact, and Telegram returns the number IT verified at signup.
-- That is real proof of ownership — no SMS, no cost.
--
-- status flow:  awaiting_contact -> verified
alter table tg_login_codes
  add column if not exists phone text;
