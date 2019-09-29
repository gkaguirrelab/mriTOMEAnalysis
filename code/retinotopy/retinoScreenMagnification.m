% During Session 2 scanning of the TOME study, subjects maintained central
% fixation during presentation of a retinotopic mapping stimulus. Some
% subjects wore contact or spectacle lenses during the scan. For these
% subjects (all of whom had negative lenses for correction of myopia) the
% stimuli on the screen were therefore minified, subtending a smaller
% visual angle than subjects without corrective lenses. I calculate here
% the degree of magnification. This value is used to adjust the conversion
% of screen coordinates to visual angle coordinates in the retinotopic
% mapping analysis.

subjects = {'TOME_3001','TOME_3002','TOME_3003','TOME_3004','TOME_3005','TOME_3007','TOME_3008','TOME_3009','TOME_3011','TOME_3012','TOME_3013','TOME_3014','TOME_3015','TOME_3016','TOME_3017','TOME_3018','TOME_3019','TOME_3020','TOME_3021','TOME_3022','TOME_3023','TOME_3023','TOME_3024','TOME_3025','TOME_3026','TOME_3028','TOME_3029 ','TOME_3030','TOME_3031','TOME_3032','TOME_3033','TOME_3034','TOME_3035','TOME_3036','TOME_3037','TOME_3038','TOME_3039','TOME_3040','TOME_3042','TOME_3043','TOME_3044','TOME_3045'};
axialLength = [24.49	25.15	27.52	24.03	22.76	22.18	26.05	24.90	23.89	24.92	27.49	24.79	23.45	22.69	22.90	24.83	25.35	25.35	25.29	22.64	26.54	26.54	25.47	24.18	25.35	23.45	22.44	22.88	24.06	23.67	23.73	24.01	24.5	25.7	23.56	22.17	23.39	22.11	24.23	21.89	24.85	26.24];
sphericalAmetropia = [-3.25	-1.75	-7.5	0.25	-0.5	-0.75	-8.5	-3.75	-5.25	-2	-10.25	-2	-0.5	-1.25	0.75	-1	-0.5	-1.5	-5.25	0	-6	-6	-2	-0.75	-5	-0.75	0.5	0.25	-0.25	0.5	-0.25	-1.75	0.25	-5.25	-1	-1	-0.5	0.25	-1.5	3.5	-5	-6.25];
spectacleLens = {[],[],-7.5,[],[],[],[],-3,[],[],[],[],[],[],[],-2,[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],-6.5};
contactLens = {-3.25,-1.75,[],[],[],[],-8.5,[],-5.25,[],-8.5,[],[],[],[],[],[],[],-5.25,[],-6,-6,-2,[],-5,[],[],[],[],[],[],[],[],-5.25,[],[],[],[],[],[],-5,[]};
measuredCornealCurvature = {[43.32,44.47,23],[41.77,43.55,25],[41.56,42.35,5],[],[45.30,46.23,8],[],[],[44.23,44.94,156],[45.79,46.68,0],[],[41.62,43.66,174],[],[],[],[],[],[],[41.36,41.67,25],[],[],[],[],[],[],[],[],[],[45.42,45.42,42],[42.03,42.51,1],[42.61,43.72,173],[],[45.49,45.86,166],[41.21,42.29,178],[41.87,42.72,26],[45.61,45.86,48],[46.87,47.34,163],[43.66,44.64,178],[45.92,47.14,17],[],[43.38, 43.95, 166],[44.00, 45.30, 5],[43.83, 43.89, 165]};

for ii=1:length(subjects)
    
    magnification = 1;

    sceneGeometry = createSceneGeometry(...
        'axialLength',axialLength(ii),...
        'sphericalAmetropia',sphericalAmetropia(ii),...
            'measuredCornealCurvature',measuredCornealCurvature{ii},...
        'spectacleLens',spectacleLens{ii},...
        'contactLens',contactLens{ii});


    if isfield(sceneGeometry.refraction.retinaToCamera,'magnification')
        if isfield(sceneGeometry.refraction.retinaToCamera.magnification,'contact')
            magnification = sceneGeometry.refraction.retinaToCamera.magnification.contact;
        end        
        if isfield(sceneGeometry.refraction.retinaToCamera.magnification,'spectacle')
            magnification = sceneGeometry.refraction.retinaToCamera.magnification.spectacle;
        end        
    end
    
    % Report this value
    fprintf([subjects{ii} ' screen magnification: %2.2f\n'],magnification);
end