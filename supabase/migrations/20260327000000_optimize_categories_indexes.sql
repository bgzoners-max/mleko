-- Optimizuj kategorije za brže lookup-e i sortiranje
-- Index za parent_id lookup (za getChildCategories i grouping)
CREATE INDEX IF NOT EXISTS idx_categories_parent_id
ON categories(parent_id, "order");

-- Index za order sorting (ako se često sortira samo po order)
CREATE INDEX IF NOT EXISTS idx_categories_order
ON categories("order");

-- Composite index za kombinovanu pretagu (parent_id i order)
-- Smanjuje potrebu za multi-step soriranjem
COMMENT ON INDEX idx_categories_parent_id IS 'Enables fast category grouping by parent and ordering within groups';
