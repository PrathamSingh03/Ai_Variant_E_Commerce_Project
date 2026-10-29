// =============================================================================
// Olist Store Analysis - Excel Power Query steps (data cleaning)
// Copied from the Power Query editor of the project workbook; local file paths
// were replaced with a DataFolder placeholder. Define it once as a text query:
//     DataFolder = "C:\path\to\olist_csv"
// Notes on what each step does are in README.md in this folder.
// =============================================================================
section Section1;

shared olist_customers_dataset = let
    Source = Csv.Document(File.Contents(DataFolder & "\olist_customers_dataset.csv"),[Delimiter=",", Columns=5, Encoding=1252, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"customer_id", type text}, {"customer_unique_id", type text}, {"customer_zip_code_prefix", Int64.Type}, {"customer_city", type text}, {"customer_state", type text}})
in
    #"Changed Type";


shared olist_geolocation_dataset = let
    Source = Csv.Document(File.Contents(DataFolder & "\olist_geolocation_dataset.csv"),[Delimiter=",", Columns=5, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"geolocation_zip_code_prefix", Int64.Type}, {"geolocation_lat", type number}, {"geolocation_lng", type number}, {"geolocation_city", type text}, {"geolocation_state", type text}}),
    #"Replaced Value" = Table.ReplaceValue(#"Changed Type","sao paulo","são paulo",Replacer.ReplaceText,{"geolocation_city"}),
    #"Removed Duplicates" = Table.Distinct(#"Replaced Value", {"geolocation_city"}),
    #"Replaced Value1" = Table.ReplaceValue(#"Removed Duplicates","sãopaulo","são paulo",Replacer.ReplaceText,{"geolocation_city"}),
    #"Replaced Value2" = Table.ReplaceValue(#"Replaced Value1","sa£o paulo","são paulo",Replacer.ReplaceText,{"geolocation_city"})
in
    #"Replaced Value2";


shared olist_order_items_dataset = let
    Source = Csv.Document(File.Contents(DataFolder & "\olist_order_items_dataset.csv"),[Delimiter=",", Columns=7, Encoding=1252, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"order_id", type text}, {"order_item_id", Int64.Type}, {"product_id", type text}, {"seller_id", type text}, {"shipping_limit_date", type datetime}, {"price", type number}, {"freight_value", type number}})
in
    #"Changed Type";


shared olist_order_payments_dataset = let
    Source = Csv.Document(File.Contents(DataFolder & "\olist_order_payments_dataset.csv"),[Delimiter=",", Columns=5, Encoding=1252, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"order_id", type text}, {"payment_sequential", Int64.Type}, {"payment_type", type text}, {"payment_installments", Int64.Type}, {"payment_value", type number}})
in
    #"Changed Type";


shared olist_order_reviews_dataset = let
    Source = Csv.Document(File.Contents(DataFolder & "\olist_order_reviews_dataset.csv"),[Delimiter=",", Columns=7, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"review_id", type text}, {"order_id", type text}, {"review_score", Int64.Type}, {"review_comment_title", type text}, {"review_comment_message", type text}, {"review_creation_date", type datetime}, {"review_answer_timestamp", type datetime}})
in
    #"Changed Type";


shared olist_orders_dataset = let
    Source = Csv.Document(File.Contents(DataFolder & "\olist_orders_dataset.csv"),[Delimiter=",", Columns=8, Encoding=1252, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"order_id", type text}, {"customer_id", type text}, {"order_status", type text}, {"order_purchase_timestamp", type datetime}, {"order_approved_at", type datetime}, {"order_delivered_carrier_date", type datetime}, {"order_delivered_customer_date", type datetime}, {"order_estimated_delivery_date", type datetime}}),
    #"Removed Blank Rows" = Table.SelectRows(#"Changed Type", each not List.IsEmpty(List.RemoveMatchingItems(Record.FieldValues(_), {"", null})))
in
    #"Removed Blank Rows";


shared olist_products_dataset = let
    Source = Csv.Document(File.Contents(DataFolder & "\olist_products_dataset.csv"),[Delimiter=",", Columns=9, Encoding=1252, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"product_id", type text}, {"product_category_name", type text}, {"product_name_lenght", Int64.Type}, {"product_description_lenght", Int64.Type}, {"product_photos_qty", Int64.Type}, {"product_weight_g", Int64.Type}, {"product_length_cm", Int64.Type}, {"product_height_cm", Int64.Type}, {"product_width_cm", Int64.Type}}),
    #"Replaced Value" = Table.ReplaceValue(#"Changed Type","","unknown",Replacer.ReplaceValue,{"product_category_name"})
in
    #"Replaced Value";


shared olist_sellers_dataset = let
    Source = Csv.Document(File.Contents(DataFolder & "\olist_sellers_dataset.csv"),[Delimiter=",", Columns=4, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"seller_id", type text}, {"seller_zip_code_prefix", Int64.Type}, {"seller_city", type text}, {"seller_state", type text}})
in
    #"Changed Type";


shared product_category_name_translation = let
    Source = Csv.Document(File.Contents(DataFolder & "\product_category_name_translation.csv"),[Delimiter=",", Columns=2, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Changed Type" = Table.TransformColumnTypes(Source,{{"Column1", type text}, {"Column2", type text}}),
    #"Promoted Headers" = Table.PromoteHeaders(#"Changed Type", [PromoteAllScalars=true]),
    #"Changed Type1" = Table.TransformColumnTypes(#"Promoted Headers",{{"product_category_name", type text}, {"product_category_name_english", type text}})
in
    #"Changed Type1";


shared Geo_Zip_Lookup = let
    Source = olist_geolocation_dataset,
    #"Grouped Rows" = Table.Group(Source, {"geolocation_zip_code_prefix"}, {{"Avg_Lat", each List.Average([geolocation_lat]), type nullable number}, {"Avg_Lng", each List.Average([geolocation_lng]), type nullable number}})
in
    #"Grouped Rows";


shared #"Geo_Zip_Lookup (2)" = let
    Source = olist_geolocation_dataset,
    #"Grouped Rows" = Table.Group(Source, {"geolocation_zip_code_prefix"}, {{"Avg_Lat", each List.Average([geolocation_lat]), type nullable number}, {"Avg_Lng", each List.Average([geolocation_lng]), type nullable number}})
in
    #"Grouped Rows";

