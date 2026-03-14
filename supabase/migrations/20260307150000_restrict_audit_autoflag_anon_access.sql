-- Restrict anonymous access to internal ordering/listing audit artifacts.
-- Keep authenticated access for in-app seller/admin tooling.

REVOKE EXECUTE ON FUNCTION public.audit_product_ordering(int) FROM anon;
REVOKE SELECT ON public.ordering_audit_summary FROM anon;
REVOKE SELECT ON public.product_listing_autoflags FROM anon;
