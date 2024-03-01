update subscriptions
	set expiry_time = 1704067200000000 -- 01.01.2024
		where 
			product_id = 'free' and 
            storage = 1073741824 and -- ignore those whose plans we upgraded manually
			expiry_time < 1672531200000000; -- 01.01.2023
