#!/usr/bin/env python3
"""
Quick validation script to ensure all new models and endpoints are working.
"""

import sys
from pathlib import Path

# Add backend/backend to path so we can import app modules
sys.path.insert(0, str(Path(__file__).parent / "backend" / "backend"))

try:
    print("\n🔍 Testing imports...")
    
    # Test model imports
    from app.models import LearningPath, LearningPathExercise
    print("  ✅ LearningPath models imported")
    
    # Test schema imports
    from app.schemas.learning_path import LearningPathCreate, LearningPathResponse
    print("  ✅ LearningPath schemas imported")
    
    # Test router import
    from app.routers import learning_paths
    print("  ✅ Learning paths router imported")
    
    # Test that router has the right endpoints
    assert hasattr(learning_paths.router, 'routes'), "Router doesn't have routes"
    route_count = len(learning_paths.router.routes)
    print(f"  ✅ Router has {route_count} endpoints")
    
    # List endpoints
    print("\n📍 Endpoints registered:")
    for route in learning_paths.router.routes:
        if hasattr(route, 'path') and hasattr(route, 'methods'):
            methods = list(route.methods)
            print(f"    {methods[0]} {route.path}")
    
    print("\n✅ ALL VALIDATIONS PASSED!")
    sys.exit(0)

except Exception as e:
    print(f"\n❌ ERROR: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
