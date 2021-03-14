using System;
using System.Collections;
using System.Collections.Generic;
using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

namespace RenderPassTests
{
    [ExecuteInEditMode]
    public class SimpleRenderPipeline : RenderPipelineAsset
    {
#if UNITY_EDITOR
        [UnityEditor.MenuItem("RenderPipeline/Create SimpleRenderLoop")]
        static void CreateSimpleRenderLoop()
        {
            var instance = CreateInstance<SimpleRenderPipeline>();
            UnityEditor.AssetDatabase.CreateAsset(instance, "Assets/SimpleRenderPipeline.asset");
        }

#endif

        public enum Mode
        {
            DepthPrepass,
            OnePassAlphaTest,
            OnePassAlphaBlend
        }
        public Mode mode;

        protected override RenderPipeline CreatePipeline()
        {
            return new SimpleRenderPipelineInstance(this);
        }
    }

    public class SimpleRenderPipelineInstance : RenderPipeline
    {
        SimpleRenderPipeline m_Parent;

        public SimpleRenderPipelineInstance(SimpleRenderPipeline parent)
        {
            m_Parent = parent;
        }

        protected override void Render(ScriptableRenderContext renderContext, Camera[] cameras)
        {
            SimpleRendering.Render(renderContext, cameras, m_Parent.mode);
        }
    }

    public static class SimpleRendering
    {
        public static void Render(ScriptableRenderContext context, IEnumerable<Camera> cameras, SimpleRenderPipeline.Mode mode)
        {
            foreach (var camera in cameras)
            {
                // Culling
                ScriptableCullingParameters cullingParams;

                if (!camera.TryGetCullingParameters(out cullingParams))
                    continue;

                CullingResults cull = context.Cull(ref cullingParams);

                context.SetupCameraProperties(camera);

                AttachmentDescriptor color = new AttachmentDescriptor(RenderTextureFormat.ARGB32);
                AttachmentDescriptor depth = new AttachmentDescriptor(RenderTextureFormat.Depth);

                bool needsFinalBlit = camera.cameraType == CameraType.SceneView;

                RenderTargetIdentifier tmpBuf = new RenderTargetIdentifier("TempSurface");
                if (needsFinalBlit)
                {
                    using (var cmd = new CommandBuffer())
                    {
                        cmd.GetTemporaryRT(Shader.PropertyToID("TempSurface"), camera.pixelWidth, camera.pixelHeight, 24, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
                        context.ExecuteCommandBuffer(cmd);
                    }
                    color.ConfigureTarget(tmpBuf, false, true);
                }
                else
                    color.ConfigureTarget(BuiltinRenderTextureType.CameraTarget, false, true);

                // No configure target for depth means depth will be memoryless

                color.ConfigureClear(Color.blue / 3 + Color.red / 2);
                depth.ConfigureClear(Color.black, 1.0f, 0);

                using (var attachmentsDisposable = new NativeArray<AttachmentDescriptor>(2, Allocator.Temp))
                {
                    var attachments = attachmentsDisposable;
                    const int depthIndex = 0, colorIndex = 1;
                    attachments[depthIndex] = depth;
                    attachments[colorIndex] = color;

                    using (context.BeginScopedRenderPass(camera.pixelWidth, camera.pixelHeight, 1, attachments, depthIndex))
                    {
                        var fs = new FilteringSettings(RenderQueueRange.opaque);

                        if (mode == SimpleRenderPipeline.Mode.DepthPrepass)
                        {
                            var depthPrePasssettings = new DrawingSettings(new ShaderTagId("DepthPrepass"), new SortingSettings(camera));
                            using (var depthOnlyDisposable = new NativeArray<int>(0, Allocator.Temp))
                            {
                                var depthArray = depthOnlyDisposable;
                                using (context.BeginScopedSubPass(depthArray))
                                {
                                    context.DrawRenderers(cull, ref depthPrePasssettings, ref fs);
                                }
                            }

                            var mainPasssettings = new DrawingSettings(new ShaderTagId("AfterZPrepass"), new SortingSettings(camera));
                            using (var colorsDisposable = new NativeArray<int>(1, Allocator.Temp))
                            {
                                var colors = colorsDisposable;
                                colors[0] = colorIndex;

                                using (context.BeginScopedSubPass(colors))
                                {
                                    context.DrawRenderers(cull, ref mainPasssettings, ref fs);
                                }
                            }
                        }
                        else if (mode == SimpleRenderPipeline.Mode.OnePassAlphaTest)
                        {
                            var mainPasssettings = new DrawingSettings(new ShaderTagId("OnePassAlphaClip"), new SortingSettings(camera));
                            using (var colorsDisposable = new NativeArray<int>(1, Allocator.Temp))
                            {
                                var colors = colorsDisposable;
                                colors[0] = colorIndex;

                                using (context.BeginScopedSubPass(colors))
                                {
                                    context.DrawRenderers(cull, ref mainPasssettings, ref fs);
                                }
                            }
                        }
                        else if (mode == SimpleRenderPipeline.Mode.OnePassAlphaBlend)
                        {
                            var sortingSettings = new SortingSettings(camera);
                            sortingSettings.criteria = SortingCriteria.BackToFront;
                            var mainPasssettings = new DrawingSettings(new ShaderTagId("OnePassAlphaBlend"), sortingSettings);
                            using (var colorsDisposable = new NativeArray<int>(1, Allocator.Temp))
                            {
                                var colors = colorsDisposable;
                                colors[0] = colorIndex;

                                using (context.BeginScopedSubPass(colors))
                                {
                                    context.DrawRenderers(cull, ref mainPasssettings, ref fs);
                                }
                            }
                        }
                    }
                }

                if (needsFinalBlit)
                {
                    using (var cmd = new CommandBuffer())
                    {
                        cmd.Blit(tmpBuf, new RenderTargetIdentifier(BuiltinRenderTextureType.CameraTarget));
                        context.ExecuteCommandBuffer(cmd);
                    }
                }

                context.Submit();
            }
        }
    }
}
