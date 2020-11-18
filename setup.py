from setuptools import setup

setup(name='temoatools',
      version='2.3.0',
      description='Modeling tools to support electric sector analyses in Temoa',
      url='https://github.com/coopercenter/temoatools',
      author='Jeff Bennett',
      author_email='jab6ft@virginia.edu',
      packages=['temoatools'],
      zip_safe=False,
      include_package_data=True,
      install_requires=['pandas', 'numpy', 'matplotlib', 'seaborn', 'joblib', 'scipy', 'xlrd'])