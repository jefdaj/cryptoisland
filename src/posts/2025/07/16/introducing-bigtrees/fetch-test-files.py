#!/usr/bin/env python3

import os
import urllib.request
import zipfile
import shutil

TEST_FILE_URLS = {
    'josef-friedrichj': 'https://github.com/Josef-Friedrich/test-files/archive/refs/heads/master.zip',
    'linux-source-code': 'https://github.com/torvalds/linux/archive/refs/heads/master.zip',
}

# This can be anywhere you have 18G+ free space
[[ -z "$TMPDIR" ]] && TMPDIR=.
TEST_FILES_DIR = "$TMPDIR/test-files"

def download_test_file(name, url, retries=3, delay=5):
    out_path = os.path.join(TEST_FILES_DIR, name + '.zip')
    if not os.path.exists(out_path):
        print(f"downloading '{out_path}'... ", end='', flush=True)
        for attempt in range(retries):
            try:
                tmp_path = out_path + '.part'
                urllib.request.urlretrieve(url, tmp_path)
                os.rename(tmp_path, out_path)
                print('ok', flush=True)
                return
            except Exception as e:
                print(f'\nERROR: {e}', flush=True)
                if os.path.exists(tmp_path):
                    os.remove(tmp_path)
                if attempt < retries - 1:
                    print(f"Retrying in {delay} seconds... ({attempt + 1}/{retries})")
                    time.sleep(delay)
                else:
                    print("Max retries reached. Download failed.", flush=True)
                    raise

def unzip_test_dir(name):
    unzip_dir = os.path.join(TEST_FILES_DIR, name)
    zip_path  = os.path.join(TEST_FILES_DIR, name + '.zip')
    os.makedirs(unzip_dir, exist_ok=True) # TODO remove?
    print(f"unzipping '{zip_path}'... ", end='', flush=True)
    try:
        with zipfile.ZipFile(zip_path, 'r') as f:
            f.extractall(unzip_dir)
        print('ok', flush=True)
    except:
        print('ERROR', flush=True)
        raise

def duplicate_test_dir(name, n_dupes=3):
    test_dir = os.path.join(TEST_FILES_DIR, name)
    for n in range(1, n_dupes+1):
        dupe_dir = test_dir + f'-dupe{n}'
        print(f"copying '{test_dir}' -> '{dupe_dir}'... ", end='', flush=True)
        try:
            shutil.copytree(test_dir, dupe_dir)
            print('ok')
        except:
            print('ERROR')
            raise

def main():
    os.makedirs(TEST_FILES_DIR, exist_ok=True)
    for name, url in TEST_FILE_URLS.items():
        download_test_file(name, url)
        unzip_test_dir(name)
        duplicate_test_dir(name, n_dupes=9)

if __name__ == '__main__':
    main()
