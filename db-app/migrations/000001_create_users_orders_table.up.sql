
CREATE TABLE users (
		user_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
		name varchar(100) not null,
		email varchar(50) not null,
		address varchar(100) not null,
		password varchar(100) unique not null
);

CREATE TABLE orders (
		id bigint generated always as identity primary key,
		user_id uuid references users(user_id) on delete cascade,
		sku bigint,
		price double precision
);
