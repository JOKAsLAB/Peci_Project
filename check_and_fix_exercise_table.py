#!/usr/bin/env python
"""Check and fix exercise table schema"""

import asyncio
import sys
import os
from pathlib import Path

# Add backend to path
backend_path = Path(__file__).parent / "backend"
sys.path.insert(0, str(backend_path))

from sqlalchemy import inspect, text
from backend.app.database import engine

async def main():
    async with engine.begin() as conn:
        # Check existing columns
        columns = await conn.run_sync(
            lambda c: [col['name'] for col in inspect(c).get_columns('exercise')]
        )
        
        print(f"Current columns in exercise table: {columns}")
        
        if 'published' not in columns:
            print("\n⚠️  Column 'published' is MISSING. Adding it now...")
            try:
                await conn.execute(
                    text("""
                    ALTER TABLE exercise 
                    ADD COLUMN published BOOLEAN NOT NULL DEFAULT false;
                    """)
                )
                await conn.commit()
                print("✅ Column 'published' added successfully!")
                
                # Verify
                columns = await conn.run_sync(
                    lambda c: [col['name'] for col in inspect(c).get_columns('exercise')]
                )
                print(f"Updated columns: {columns}")
            except Exception as e:
                print(f"❌ Error adding column: {e}")
                sys.exit(1)
        else:
            print("\n✅ Column 'published' already exists!")

if __name__ == "__main__":
    asyncio.run(main())
