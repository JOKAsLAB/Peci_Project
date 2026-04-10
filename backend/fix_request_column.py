#!/usr/bin/env python3
"""
Fix missing request_type column in Request table
"""
import asyncio
import sys
sys.path.insert(0, '.')

from sqlalchemy import text
from app.database import get_db_engine

async def fix_request_table():
    try:
        engine = get_db_engine()
        async with engine.connect() as conn:
            # Add the missing request_type column
            await conn.execute(text(
                'ALTER TABLE request ADD COLUMN request_type VARCHAR(20) NOT NULL DEFAULT \'other\''
            ))
            await conn.commit()
            print('✓ Successfully added request_type column to request table')
            return True
    except Exception as e:
        if 'already exists' in str(e):
            print('✓ Column request_type already exists')
            return True
        print(f'✗ Error: {e}')
        return False

if __name__ == '__main__':
    success = asyncio.run(fix_request_table())
    sys.exit(0 if success else 1)
