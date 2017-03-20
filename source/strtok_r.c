// Public domain strtok_r() by Charlie Gordon
// from comp.lang.c  14 Sep 2007

char* strtok_r(
    char *str,
    const char *delim,
    char **nextp)
{
    char *ret;
    if (str == NULL)
    {
        str = *nextp;
    }
    str += strspn(str, delim);
    if (*str == '\0')
    {
        return NULL;
    }
    ret = str;
    str += strcspn(str, delim);
    if (*str)
    {
        *str++ = '\0';
    }
    *nextp = str;
    return ret;
}
