-- Updateuj Edge Config za produkciju - ispravka push notifikacija
UPDATE public.edge_config
SET value = 'https://wvqtujpurhzraptorcvl.supabase.co'
WHERE key = 'functions_base_url';

UPDATE public.edge_config
SET value = 'sb_publishable_fctLgkfcyV3HtMIHkO6lvw_NdmiBrsX'
WHERE key = 'anon_key';
