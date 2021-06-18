# -*- coding: utf-8 -*-
"""
Created on Tue Apr 27 14:58:59 2021

@author: mangotee
"""


run iemap_seg.py 
    --input_head_volumes P10_T2.nii.gz P10_T1.nii.gz 
    --matching_template_modalities_head T2 T1
    --input_ie_volumes P10_T2.nii.gz P10_CISS.nii.gz P10_T2space.nii.gz 
    --matching_template_modalities_ie T2 CISS CISS
    --output_dir D:\Projects\IEMapAtlasSegmentation\data\test\P10\out 
    --accuracy_head normal 
    --accuracy_ie normal accurate
    
run iemap_seg.py 
    --input_head_volumes P10_T2.nii.gz P10_T1.nii.gz
    --matching_template_modalities_head T2 T1
    --input_ie_volumes P10_T2.nii.gz
    --matching_template_modalities_ie T2
    --output_dir D:\Projects\IEMapAtlasSegmentation\data\test\P10\out 
    --accuracy_head normal 
    --accuracy_ie normal accurate
    
    
run iemap_seg.py 
    --input_head_volumes D:\Projects\IEMapAtlasSegmentation\data\test\P10\P10_T2.nii.gz 
    --matching_template_modalities_head T2 
    --input_ie_volumes D:\Projects\IEMapAtlasSegmentation\data\test\P10\P10_T2.nii.gz 
    --matching_template_modalities_ie T2 
    --output_dir D:\Projects\IEMapAtlasSegmentation\data\test\P10\out 
    --accuracy_head normal 
    --accuracy_ie normal accurate
    
    
python iemap_seg.py --input_head_volumes '/home/ozzy/Desktop/IEsegTest/TOME_3045_T2.nii.gz' --matching_template_modalities_head T2 --input_ie_volumes '/home/ozzy/Desktop/IEsegTest/TOME_3045_T2.nii.gz' --matching_template_modalities_ie T2 --output_dir '/home/ozzy/Desktop/IEsegTest/output/' --accuracy_head very_accurate --accuracy_ie very_accurate
