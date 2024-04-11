"""increase webhook max length

Revision ID: c65acfa00814
Revises: ba2b62aab22b
Create Date: 2024-04-11 15:25:39.293639

"""

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "c65acfa00814"
down_revision: Union[str, None] = "ba2b62aab22b"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column("subscriber", "webhook_url", type_=sa.String(200))


def downgrade() -> None:
    op.alter_column("subscriber", "webhook_url", type_=sa.String(50))
