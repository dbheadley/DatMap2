%% uses a binary search to find the closest value
function ind = FindClosest(val, list)
  if isempty(list)
    ind = NaN;
    return;
  end
  
  window = [1 numel(list)];
  while (window(2)-window(1))>1
    compInd = window(1) + round((window(2)-window(1))/2);
    compVal = list(compInd);
    
    if val == compVal
      ind = compInd;
      return;
    elseif val < compVal
      window(2) = compInd-1;
    else
      window(1) = compInd+1;
    end
  end

  if abs(list(window(1))-val) > abs(list(window(2))-val)
    ind = window(2);
  else
    ind = window(1);
  end
  
  if ind ~= 1
    if abs(list(ind-1)-val) < abs(list(ind)-val)
      ind = ind - 1;
    end
  end
  
  if abs(list(ind)-val) > abs(list(1 + round((numel(list)-1)/2)) - val)
      ind = 1 + round((numel(list)-1)/2);
  end
end