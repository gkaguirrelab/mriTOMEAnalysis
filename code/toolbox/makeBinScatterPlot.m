function makeBinScatterPlot(x, y)

[count,edges] = histcounts(x);

for ii = 1:length(edges) - 1
    xValuesWithinThisBin = find(x < edges(ii+1) & x > edges(ii));
    meanXValueForThisBin(ii) = mean([edges(ii+1), edges(ii)]);
    meanOfCorrespondingYValues(ii) = nanmean(y(xValuesWithinThisBin));
end

plot(meanXValueForThisBin, meanOfCorrespondingYValues, 'Color', 'r');
plot(meanXValueForThisBin, meanOfCorrespondingYValues, 'o', 'Color', 'r');

    

end