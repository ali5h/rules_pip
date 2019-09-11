# just try to import some packages that use namespace
import google.cloud.language as lang
import testing.postgresql as psql
import testing.mysqld as mysql


# for linters
__all__ = ["lang", "psql", "mysql"]
