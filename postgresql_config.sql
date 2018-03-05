CREATE DATABASE fondefviz;
CREATE USER inspector WITH PASSWORD 'fondefviz';
GRANT ALL PRIVILEGES ON DATABASE fondefviz TO fondefvizuser;
ALTER USER fondefvizuser CREATEDB;
\q
