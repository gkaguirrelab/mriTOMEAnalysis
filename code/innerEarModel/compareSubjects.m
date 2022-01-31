tome = plotAllSubjects('C:\Users\ozenc\Documents\MATLAB\projects\mriTOMEAnalysis\code\innerEarModel\Cammille_results\innerEarNormals');
% dataset1 = plotAllSubjects('C:\Users\ozenc\Desktop\ForOzzy\ForOzzy\dataset-1');
% dataset2 = plotAllSubjects('C:\Users\ozenc\Desktop\ForOzzy\ForOzzy\dataset-2');
% 
% averages{1,1} = [0 0 0];
% averages{1,2} = [0 0 0];
% averages{1,3} = [0 0 0];
% averages{1,4} = [0 0 0];
% averages{1,5} = [0 0 0];
% averages{1,6} = [0 0 0];
% averages{2,1} = [0 0 0];
% averages{2,2} = [0 0 0];
% averages{2,3} = [0 0 0];
% averages{2,4} = [0 0 0];
% averages{2,5} = [0 0 0];
% averages{2,6} = [0 0 0];
% averages{3,1} = [0 0 0];
% averages{3,2} = [0 0 0];
% averages{3,3} = [0 0 0];
% averages{3,4} = [0 0 0];
% averages{3,5} = [0 0 0];
% averages{3,6} = [0 0 0];
% 
% for ii = 1:length(tome)
%     averages{1,1} = averages{1,1} + tome{ii,1};
%     averages{1,2} = averages{1,2} + tome{ii,2};
%     averages{1,3} = averages{1,3} + tome{ii,3};
%     averages{1,4} = averages{1,4} + tome{ii,4};
%     averages{1,5} = averages{1,5} + tome{ii,5};
%     averages{1,6} = averages{1,6} + tome{ii,6};
% end
% 
% for ii = 1:length(dataset1)
%     averages{2,1} = averages{2,1} + dataset1{ii,1};
%     averages{2,2} = averages{2,2} + dataset1{ii,2};
%     averages{2,3} = averages{2,3} + dataset1{ii,3};
%     averages{2,4} = averages{2,4} + dataset1{ii,4};
%     averages{2,5} = averages{2,5} + dataset1{ii,5};
%     averages{2,6} = averages{2,6} + dataset1{ii,6};
% end
% 
% for ii = 1:length(dataset2)
%     averages{3,1} = averages{3,1} + dataset2{ii,1};
%     averages{3,2} = averages{3,2} + dataset2{ii,2};
%     averages{3,3} = averages{3,3} + dataset2{ii,3};
%     averages{3,4} = averages{3,4} + dataset2{ii,4};
%     averages{3,5} = averages{3,5} + dataset2{ii,5};
%     averages{3,6} = averages{3,6} + dataset2{ii,6};
% end
% 
% tomeLeft = (averages{1,1} + averages{1,3} + averages{1,5})/3; 
% tomeRight = (averages{1,2} + averages{1,4} + averages{1,6})/3;
% tomeHead = (tomeLeft + tomeRight)/2;
% 
% dataOneLeft = (averages{2,1} + averages{2,3} + averages{2,5})/3; 
% dataOneRight = (averages{2,2} + averages{2,4} + averages{2,6})/3;  
% dataOneHead = (dataOneLeft + dataOneRight)/2;
% 
% dataTwoLeft = (averages{3,1} + averages{3,3} + averages{3,5})/3; 
% dataTwoRight = (averages{3,2} + averages{3,4} + averages{3,6})/3; 
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
