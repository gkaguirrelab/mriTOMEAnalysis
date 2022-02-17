function modelCompare(subjectFolder)

[LateralVector, AnteriorVector, PosteriorVector,...
 LateralVectorOtherEar, AnteriorVectorOtherEar, PosteriorVectorOtherEar] =  model();

rightEar = [LateralVector, AnteriorVector, PosteriorVector];
leftEar = [LateralVectorOtherEar, AnteriorVectorOtherEar, PosteriorVectorOtherEar];

% Get the mean vector for right and left
rMean = mean(rightEar);
lMean = mean(leftEar);

% Load subject variables 
[lateralMRILeft, lateralMRIRight, ...
 anteriorMRILeft, anteriorMRIRight, ...
 posteriorMRILeft, posteriorMRIRight] = loadMRINormals(subjectFolder);

% Get mean vector for the subject
rMRI = [lateralMRIRight.normal', anteriorMRIRight.normal', posteriorMRIRight.normal'];
lMRI = [lateralMRILeft.normal', anteriorMRILeft.normal', posteriorMRILeft.normal'];

rMeanMRI = mean(rMRI);
lMeanMRI = mean(lMRI);

% Calculate right cosine similarity between means
dotProduct = dot(rMean, rMeanMRI);
magnitudeProduct = norm(rMean) * norm(rMeanMRI);
similarity = dotProduct / magnitudeProduct;
fprintf(['Similarity of right ear is ' num2str(similarity) '\n'])

% Calculate left cosine similarity between means
dotProduct = dot(lMean, lMeanMRI);
magnitudeProduct = norm(lMean) * norm(lMeanMRI);
similarity = dotProduct / magnitudeProduct;
fprintf(['Similarity of left ear is ' num2str(similarity)])

end
