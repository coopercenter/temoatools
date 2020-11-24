import os
import shutil

# update va_emerging_tech to use latest data files from the test_emerging_tech project
source = os.path.abspath('../test_emerging_tech/data')
destination = os.path.abspath('./data')
files_to_copy = ['data_virginia.xlsx', 'data_emerging_tech.xlsx', 'data_H2_VFB.xlsx', 'monte_carlo_inputs.xlsx']

# remove existing files
os.chdir(destination)
for file in files_to_copy:
    if os.path.isfile(file):
        os.remove(file)

# copy specified files
for file in files_to_copy:
    src = os.path.join(source, file)
    dst = os.path.join(destination, file)
    shutil.copy(src, dst)

# --------------------
# alternative - copying everything
# --------------------
# # https://stackoverflow.com/questions/12683834/how-to-copy-directory-recursively-in-python-and-overwrite-all
# if os.path.exists(destination):
#     shutil.rmtree(destination)
# shutil.copytree(source, destination)
