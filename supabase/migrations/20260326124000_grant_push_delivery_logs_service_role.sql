-- Allow Edge Function (service_role via PostgREST) to write/read push delivery logs.

GRANT USAGE ON SCHEMA public TO service_role;
GRANT SELECT, INSERT ON TABLE public.push_delivery_logs TO service_role;
GRANT USAGE, SELECT ON SEQUENCE public.push_delivery_logs_id_seq TO service_role;
