import pandas as pd
import pyodbc
from pathlib import Path

# Caminho da pasta do projeto
BASE_PATH = Path(__file__).resolve().parent.parent

# Pasta onde estão os arquivos CSV
DATA_PATH = BASE_PATH / "Data"

# ============================================================
# CONFIGURAÇÕES
# ============================================================
# Informe aqui a instância do SQL Server utilizada localmente.
# Exemplo: r"localhost\SQLEXPRESS"

SERVER = r"SEU_SERVIDOR\SQLEXPRESS"
DATABASE = "DUX_olist"



CONNECTION_STRING = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)

CHUNK_SIZE = 10_000


# ============================================================
# CONFIGURAÇÃO DAS TABELAS
# ============================================================

TABLES = {
    "olist_orders_dataset.csv": {
       "table": "dbo.olist_orders",
        "date_columns": [] 
    },

    "olist_customers_dataset.csv": {
        "table": "dbo.olist_customers",
        "date_columns": []
    },

    "olist_sellers_dataset.csv": {
        "table": "dbo.olist_sellers",
        "date_columns": []
    },

    "olist_order_items_dataset.csv": {
        "table": "dbo.olist_order_items",
        "date_columns": [
            "shipping_limit_date"
        ]
    },

    "olist_geolocation_dataset.csv": {
        "table": "dbo.olist_geolocation",
        "date_columns": []
    },

    "olist_products_dataset.csv": {
        "table": "dbo.olist_products",
        "date_columns": []
    },

    "product_category_name_translation.csv": {
        "table": "dbo.olist_category_name_translation",
        "date_columns": []
    },

    "olist_order_payments_dataset.csv": {
        "table": "dbo.olist_order_payments",
        "date_columns": []
    },

    "olist_order_reviews_dataset.csv": {
        "table": "dbo.olist_order_reviews",
        "date_columns": [
            "review_creation_date",
            "review_answer_timestamp"
        ]
    }
}


# ============================================================
# FUNÇÃO DE CARGA
# ============================================================

def load_table(filename, config, conn):

    csv_path = f"{DATA_PATH}\\{filename}" 
    table_name = config["table"]
    date_columns = config["date_columns"]

    print("\n" + "=" * 60)
    print(f"Carregando: {filename}")
    print(f"Tabela:     {table_name}")
    print("=" * 60)

    cursor = conn.cursor()
    cursor.fast_executemany = True

    # --------------------------------------------------------
    # Descobre as colunas da tabela no SQL Server
    # --------------------------------------------------------

    schema, table = table_name.split(".")

    cursor.execute("""
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = ?
          AND TABLE_NAME = ?
        ORDER BY ORDINAL_POSITION
    """, (schema, table))

    columns = [row[0] for row in cursor.fetchall()]

    if not columns:
        raise Exception(f"Tabela {table_name} não encontrada.")

    print(f"Colunas encontradas: {len(columns)}")

    # --------------------------------------------------------
    # Limpa a tabela antes da carga
    # --------------------------------------------------------

    cursor.execute(f"TRUNCATE TABLE {table_name}")
    conn.commit()

    # --------------------------------------------------------
    # Lê o CSV em partes
    # --------------------------------------------------------

    total_inserted = 0

    for chunk in pd.read_csv(
        csv_path,
        encoding="utf-8",
        chunksize=CHUNK_SIZE
    ):

        # Garante a mesma ordem das colunas
        chunk = chunk[columns]

        # ----------------------------------------------------
        # Converte datas
        # ----------------------------------------------------

        for column in date_columns:
            chunk[column] = pd.to_datetime(
                chunk[column],
                errors="coerce"
            )

        # ----------------------------------------------------
        # NaN / NaT -> None
        # SQL Server entende None como NULL
        # ----------------------------------------------------

        chunk = chunk.astype(object).where(
            pd.notna(chunk),
            None
        )

        # ----------------------------------------------------
        # Monta INSERT
        # ----------------------------------------------------

        placeholders = ", ".join(["?"] * len(columns))
        column_list = ", ".join(columns)

        sql = f"""
            INSERT INTO {table_name}
            ({column_list})
            VALUES ({placeholders})
        """

        data = list(
            chunk.itertuples(
                index=False,
                name=None
            )
        )

        cursor.executemany(sql, data)

        conn.commit()

        total_inserted += len(data)

        print(
            f"  Inseridos: {total_inserted:,}",
            end="\r"
        )

    cursor.close()

    print()
    print(f"Concluído: {total_inserted:,} registros")

    return total_inserted


# ============================================================
# EXECUÇÃO
# ============================================================

def main():

    print("Conectando ao SQL Server...")

    conn = pyodbc.connect(CONNECTION_STRING)

    print("Conexão realizada com sucesso.")

    results = {}

    try:

        for filename, config in TABLES.items():

            total = load_table(
                filename,
                config,
                conn
            )

            results[filename] = total

    finally:

        conn.close()

    # ========================================================
    # RESUMO
    # ========================================================

    print("\n")
    print("=" * 60)
    print("RESUMO DA CARGA")
    print("=" * 60)

    for filename, total in results.items():
        print(f"{filename:<45} {total:>10,}")

    print("=" * 60)
    print("Carga finalizada.")


if __name__ == "__main__":
    main()