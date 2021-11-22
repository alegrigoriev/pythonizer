
def perl_list(lst, count=None):
   """ Handle list assignment in perl"""
   if count is None:
      return lst

   if lst is None:
      return [None for _ in range(count)]

   if len(lst) == count:
      return lst

   if len(lst) > count:
      return lst[:count]

   return lst + [None for _ in range(count-len(lst))]
