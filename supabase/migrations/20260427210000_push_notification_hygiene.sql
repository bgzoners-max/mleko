-- Notification Hygiene & Duplicate Prevention
-- 1. Ensure user_push_tokens has a unique constraint on token itself.
-- This prevents the same device from having multiple entries under different installation_ids.

-- Cleanup duplicate tokens first (keep only the most recent one for each token string)
DELETE FROM public.user_push_tokens a
USING public.user_push_tokens b
WHERE a.id < b.id 
  AND a.token = b.token;

-- Add unique constraint if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_push_tokens_token_key') THEN
        ALTER TABLE public.user_push_tokens ADD CONSTRAINT user_push_tokens_token_key UNIQUE (token);
    END IF;
END $$;

-- 2. Aggressively drop any suspected legacy duplicate triggers on messages and orders
DROP TRIGGER IF EXISTS on_message_inserted ON public.messages;
DROP TRIGGER IF EXISTS trg_notify_new_message ON public.messages;
DROP TRIGGER IF EXISTS notify_new_message_trigger ON public.messages;

-- Ensure on_new_message is the ONLY trigger for chat notifications
-- We don't drop on_message_insert because it's used for updating conversation.updated_at

-- 3. Consolidate notify_new_message logic (ensure it's robust)
CREATE OR REPLACE FUNCTION public.notify_new_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_buyer_id UUID;
  v_seller_id UUID;
  v_recipient_id UUID;
  v_sender_name TEXT;
BEGIN
  -- Avoid self-notifications
  SELECT buyer_id, seller_id INTO v_buyer_id, v_seller_id
  FROM public.conversations WHERE id = NEW.conversation_id;

  IF NEW.sender_id = v_buyer_id THEN
    v_recipient_id := v_seller_id;
  ELSE
    v_recipient_id := v_buyer_id;
  END IF;

  -- If for some reason we can't find recipient, don't crash
  IF v_recipient_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(NULLIF(btrim(farm_name), ''), NULLIF(btrim(display_name), ''), 'Korisnik') INTO v_sender_name
  FROM public.profiles WHERE id = NEW.sender_id;

  -- Use UPSERT to prevent duplicate notifications for the exact same message in the same second
  -- (rare but protects against weird trigger edge cases)
  INSERT INTO public.notifications (user_id, type, title, body, conversation_id)
  VALUES (
    v_recipient_id,
    'new_message',
    'Nova poruka 💬',
    COALESCE(v_sender_name, 'Korisnik') || ': ' || LEFT(NEW.body, 80),
    NEW.conversation_id
  )
  ON CONFLICT DO NOTHING;
  
  RETURN NEW;
END;
$$;

-- 4. Cleanup old order triggers again just to be safe
DROP TRIGGER IF EXISTS on_new_order ON public.orders;
DROP TRIGGER IF EXISTS trg_notify_new_order ON public.orders;
DROP TRIGGER IF EXISTS notify_new_order_trigger ON public.orders;

-- 5. Fix potential duplication in notifications trigger itself
-- Ensure only ONE trigger exists for push invocation
DROP TRIGGER IF EXISTS notify_push_trigger ON public.notifications;
DROP TRIGGER IF EXISTS trg_invoke_send_push ON public.notifications;
-- The active one should be on_notification_insert_send_push (from 20260227220000)
