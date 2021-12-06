% [allNormalsTome, averageNormalsTome] = plotAllSubjects('C:\Users\ozenc\Desktop\tome');
[allNormalsDataOne, averageNormalsDataOne] = plotAllSubjects('C:\Users\ozenc\Desktop\ForOzzy\ForOzzy\dataset-1');
% [allNormalsDataTwo, averageNormalsDataTwo] = plotAllSubjects('C:\Users\ozenc\Desktop\ForOzzy\ForOzzy\dataset-2');
% 
% tomeLeft = (averageNormalsTome(1).normal + averageNormalsTome(2).normal + averageNormalsTome(3).normal)/3; 
% tomeRight = (averageNormalsTome(4).normal + averageNormalsTome(5).normal + averageNormalsTome(6).normal)/3;
% tomeHead = (tomeLeft + tomeRight)/2;
% 
% dataOneLeft = (averageNormalsDataOne(1).normal + averageNormalsDataOne(2).normal + averageNormalsDataOne(3).normal)/3; 
% dataOneRight = (averageNormalsDataOne(4).normal + averageNormalsDataOne(5).normal + averageNormalsDataOne(6).normal)/3;  
% dataOneHead = (dataOneLeft + dataOneRight)/2;
% 
% dataTwoLeft = (averageNormalsDataTwo(1).normal + averageNormalsDataTwo(2).normal + averageNormalsDataTwo(3).normal)/3; 
% dataTwoRight = (averageNormalsDataTwo(4).normal + averageNormalsDataTwo(5).normal + averageNormalsDataTwo(6).normal)/3; 
% dataTwoHead = (dataTwoLeft + dataTwoRight)/2;
% 
% fprintf(['Cos similarity between tome and dataset-1 is ' num2str(dot(tomeHead,dataOneHead)/(norm(tomeHead)*norm(dataOneHead))) '\n'])
% fprintf(['Cos similarity between tome and dataset-2 is ' num2str(dot(tomeHead,dataTwoHead)/(norm(tomeHead)*norm(dataTwoHead))) '\n'])
% fprintf(['Cos similarity between dataset-1 and dataset-2 is ' num2str(dot(dataOneHead,dataTwoHead)/(norm(dataOneHead)*norm(dataTwoHead))) '\n\n'])
% 
% % Tome vs dataset1
% fprintf(['Cos similarity between tomeLeft and dataset-1Left is ' num2str(dot(tomeLeft,dataOneLeft)/(norm(tomeLeft)*norm(dataOneLeft))) '\n'])
% fprintf(['Cos similarity between tomeLRight and dataset-1Right is ' num2str(dot(tomeRight,dataOneRight)/(norm(tomeRight)*norm(dataOneRight))) '\n\n'])
% 
% % Tome vs dataset2
% fprintf(['Cos similarity between tomeLeft and dataset-2Left is ' num2str(dot(tomeLeft,dataTwoLeft)/(norm(tomeLeft)*norm(dataTwoLeft))) '\n'])
% fprintf(['Cos similarity between tomeLRight and dataset-2Right is ' num2str(dot(tomeRight,dataTwoRight)/(norm(tomeRight)*norm(dataTwoRight))) '\n\n'])
% 
% % dataset1 vs dataset2
% fprintf(['Cos similarity between dataset-1Left and dataset-1Left is ' num2str(dot(dataOneLeft,dataTwoLeft)/(norm(dataOneLeft)*norm(dataTwoLeft))) '\n'])
% fprintf(['Cos similarity between dataset-1Right and dataset-1Right is ' num2str(dot(dataOneRight,dataTwoRight)/(norm(dataOneRight)*norm(dataTwoRight))) '\n\n'])
