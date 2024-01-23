import psycopg2

dbname = 'postgres'
user = 'postgres'
password = 'timonaki1234'
host = '192.168.1.107'  # or your host IP
port = '5432'  # default PostgreSQL port is 5432


class PostgresServer:
    def __init__(self):
        self.dbname = dbname
        self.user = user
        self.password = password
        self.host = host
        self.port = port
        self.conn = None

    def connect(self):
        try:
            # Establish a connection to the PostgreSQL database
            self.conn = psycopg2.connect(dbname=self.dbname,
                                    user=self.user,
                                    password=self.password,
                                    host=self.host,
                                    port=self.port)

            # Create a cursor object using the connection
            cursor = self.conn.cursor()

            # Execute a sample SQL query
            cursor.execute("SELECT version();")

            # Fetch the result
            db_version = cursor.fetchone()
            print("PostgreSQL database version:")
            print(db_version)

            # Close the cursor and connection
            cursor.close()
            # conn.close()

        except psycopg2.Error as e:
            print("Error connecting to PostgreSQL:", e)

    def get_data(self, user_id: int, size):
        if self.conn is None:
            return None
        else:
            cursor = self.conn.cursor()
            cursor.execute("SELECT * FROM params WHERE user_id = %(id)s LIMIT %(size)s",
                        {'id': user_id, 'size': size})
            return cursor.fetchall()