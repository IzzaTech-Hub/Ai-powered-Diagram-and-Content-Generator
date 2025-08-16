try:
    import app
    print('App imports successfully')
except Exception as e:
    print(f'Error importing app: {e}')
    import traceback
    traceback.print_exc()
