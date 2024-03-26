"""use JSONB

Revision ID: 7adacb84dfbe
Revises: 325c09fdc880
Create Date: 2024-03-20 11:58:33.343372

"""

from typing import Sequence, Union

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSON, JSONB

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "7adacb84dfbe"
down_revision: Union[str, None] = "325c09fdc880"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    convert_to("application", "events", JSONB, True)
    convert_to("application_version", "application", JSONB, False)


def downgrade() -> None:
    convert_to("application", "events", JSON, True)
    convert_to("application_version", "application", JSON, False)


def convert_to(table, field, column_type, nullable) -> None:
    op.alter_column(table, field, nullable=nullable, new_column_name="tmp_field")
    op.add_column(table, sa.Column(field, column_type()))

    update_rows = sa.text(f"UPDATE {table} SET {field} = tmp_field")
    connection = op.get_bind()
    connection.execute(update_rows)

    if not nullable:
        op.alter_column(table, field, nullable=nullable)

    op.drop_column(table, "tmp_field")
